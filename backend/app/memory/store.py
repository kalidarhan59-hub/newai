"""Memory store — Chroma-backed with an in-memory fallback.

The store exposes a small protocol-level surface so the orchestrator does not
depend on Chroma directly. If Chroma fails to initialise (for example in CI
without write access to the data dir) we transparently fall back to an
in-process implementation that is good enough for tests and demos.
"""

from __future__ import annotations

import json
import logging
from collections import defaultdict
from pathlib import Path
from typing import Any
from uuid import uuid4

from ..providers.base import _hash_embedding

logger = logging.getLogger(__name__)


class MemoryStore:
    """Thin wrapper around either Chroma or the in-memory fallback."""

    def __init__(self, persist_dir: Path) -> None:
        self.persist_dir = persist_dir
        self._chroma: Any | None = None
        self._collections: dict[str, Any] = {}
        self._fallback: _InMemoryStore | None = None
        self._profile_path = persist_dir.parent / "profiles.json"
        self._profiles = _load_profiles(self._profile_path)

        try:
            import chromadb

            self.persist_dir.mkdir(parents=True, exist_ok=True)
            self._chroma = chromadb.PersistentClient(path=str(self.persist_dir))
            logger.info("Memory: using Chroma at %s", self.persist_dir)
        except Exception as e:  # pragma: no cover - chroma not available
            logger.warning("Memory: Chroma unavailable (%s) — using in-memory fallback", e)
            self._fallback = _InMemoryStore()

    # ------------------------------------------------------------------
    # Collection helpers
    # ------------------------------------------------------------------

    def _get_collection(self, name: str) -> Any:
        assert self._chroma is not None
        if name not in self._collections:
            self._collections[name] = self._chroma.get_or_create_collection(name=name)
        return self._collections[name]

    # ------------------------------------------------------------------
    # CRUD
    # ------------------------------------------------------------------

    async def upsert(
        self,
        namespace: str,
        items: list[dict[str, Any]],
    ) -> list[str]:
        """Insert or update ``items`` in ``namespace``.

        Each item must have a ``text`` key. ``id`` and ``metadata`` are optional.
        """

        ids: list[str] = []
        documents: list[str] = []
        metadatas: list[dict[str, Any]] = []
        for item in items:
            iid = item.get("id") or str(uuid4())
            ids.append(iid)
            documents.append(item["text"])
            metadatas.append({k: v for k, v in item.items() if k not in ("id", "text") and v is not None})

        if self._chroma is not None:
            collection = self._get_collection(namespace)
            embeddings = [_hash_embedding(t) for t in documents]
            collection.upsert(
                ids=ids,
                documents=documents,
                metadatas=metadatas,
                embeddings=embeddings,
            )
        else:
            assert self._fallback is not None
            self._fallback.upsert(namespace, ids, documents, metadatas)
        return ids

    async def append(
        self,
        namespace: str,
        session_id: str,
        items: list[dict[str, Any]],
    ) -> list[str]:
        enriched = [{**i, "session_id": session_id} for i in items]
        return await self.upsert(namespace, enriched)

    async def search(
        self,
        namespace: str,
        *,
        query: str,
        top_k: int = 5,
        where: dict[str, Any] | None = None,
    ) -> list[dict[str, Any]]:
        if self._chroma is not None:
            collection = self._get_collection(namespace)
            try:
                result = collection.query(
                    query_embeddings=[_hash_embedding(query)],
                    n_results=top_k,
                    where=where or None,
                )
            except Exception as e:  # pragma: no cover
                logger.warning("Chroma query failed: %s", e)
                return []
            return _flatten_chroma(result)

        assert self._fallback is not None
        return self._fallback.search(namespace, query, top_k=top_k, where=where)

    async def recent(self, namespace: str, session_id: str, *, limit: int = 10) -> list[dict[str, Any]]:
        if self._chroma is not None:
            collection = self._get_collection(namespace)
            try:
                result = collection.get(where={"session_id": session_id}, limit=limit)
            except Exception:
                return []
            ids = result.get("ids", []) or []
            docs = result.get("documents", []) or []
            metas = result.get("metadatas", []) or []
            return [
                {"id": i, "text": d, **(m or {})}
                for i, d, m in zip(ids, docs, metas, strict=False)
            ][-limit:]

        assert self._fallback is not None
        return self._fallback.recent(namespace, session_id, limit)

    async def list_namespace(self, namespace: str, *, limit: int = 100) -> list[dict[str, Any]]:
        if self._chroma is not None:
            collection = self._get_collection(namespace)
            try:
                result = collection.get(limit=limit)
            except Exception:
                return []
            return [
                {"id": i, "text": d, **(m or {})}
                for i, d, m in zip(
                    result.get("ids", []) or [],
                    result.get("documents", []) or [],
                    result.get("metadatas", []) or [], strict=False,
                )
            ]
        assert self._fallback is not None
        return self._fallback.list_namespace(namespace, limit)

    # ------------------------------------------------------------------
    # Profiles
    # ------------------------------------------------------------------

    async def get_profile(self, session_id: str) -> dict[str, Any]:
        return self._profiles.get(session_id, {})

    async def update_profile(self, session_id: str, patch: dict[str, Any]) -> dict[str, Any]:
        existing = self._profiles.setdefault(session_id, {})
        existing.update(patch)
        _save_profiles(self._profile_path, self._profiles)
        return existing


# ---------------------------------------------------------------------------
# Fallback
# ---------------------------------------------------------------------------


class _InMemoryStore:
    def __init__(self) -> None:
        self._data: dict[str, list[dict[str, Any]]] = defaultdict(list)

    def upsert(
        self,
        namespace: str,
        ids: list[str],
        documents: list[str],
        metadatas: list[dict[str, Any]],
    ) -> None:
        existing = {item["id"]: idx for idx, item in enumerate(self._data[namespace])}
        for iid, doc, meta in zip(ids, documents, metadatas, strict=False):
            entry = {"id": iid, "text": doc, **meta}
            if iid in existing:
                self._data[namespace][existing[iid]] = entry
            else:
                self._data[namespace].append(entry)

    def search(
        self,
        namespace: str,
        query: str,
        *,
        top_k: int,
        where: dict[str, Any] | None,
    ) -> list[dict[str, Any]]:
        items = self._data.get(namespace, [])
        if where:
            items = [i for i in items if all(i.get(k) == v for k, v in where.items())]
        # Naive scoring: count of shared tokens.
        q_tokens = set(query.lower().split())
        scored = []
        for item in items:
            t_tokens = set(item.get("text", "").lower().split())
            score = len(q_tokens & t_tokens)
            scored.append((score, item))
        scored.sort(key=lambda x: x[0], reverse=True)
        return [{"score": float(s), **item} for s, item in scored[:top_k]]

    def recent(self, namespace: str, session_id: str, limit: int) -> list[dict[str, Any]]:
        items = [i for i in self._data.get(namespace, []) if i.get("session_id") == session_id]
        return items[-limit:]

    def list_namespace(self, namespace: str, limit: int) -> list[dict[str, Any]]:
        return list(self._data.get(namespace, []))[:limit]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _flatten_chroma(result: dict[str, Any]) -> list[dict[str, Any]]:
    ids_batches = result.get("ids") or [[]]
    docs_batches = result.get("documents") or [[]]
    metas_batches = result.get("metadatas") or [[]]
    distances_batches = result.get("distances") or [[]]
    out: list[dict[str, Any]] = []
    for ids, docs, metas, dists in zip(
        ids_batches, docs_batches, metas_batches, distances_batches, strict=False
    ):
        for iid, doc, meta, dist in zip(ids, docs, metas or [], dists or [], strict=False):
            out.append(
                {
                    "id": iid,
                    "text": doc,
                    "score": float(1.0 - (dist or 0.0)),
                    **(meta or {}),
                }
            )
    return out


def _load_profiles(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return {}


def _save_profiles(path: Path, profiles: dict[str, dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(profiles, indent=2))
