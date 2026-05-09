"""RAG pipeline — chunk, embed, retrieve."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .store import MemoryStore


@dataclass
class RAGResult:
    chunks: list[dict[str, Any]]
    namespace: str


class RAGPipeline:
    """Tiny RAG helper sitting on top of :class:`MemoryStore`.

    The MVP focuses on a small, predictable surface: ingest text into a
    namespace, retrieve the top-k chunks for a query. More advanced pieces
    (rerankers, hybrid search) plug in here later without changing callers.
    """

    def __init__(self, store: MemoryStore) -> None:
        self.store = store

    @staticmethod
    def chunk(text: str, *, max_chars: int = 800, overlap: int = 80) -> list[str]:
        text = text.strip()
        if not text:
            return []
        if len(text) <= max_chars:
            return [text]
        chunks: list[str] = []
        i = 0
        while i < len(text):
            end = min(len(text), i + max_chars)
            chunks.append(text[i:end])
            if end == len(text):
                break
            i = max(end - overlap, i + 1)
        return chunks

    async def ingest(
        self,
        namespace: str,
        text: str,
        *,
        metadata: dict[str, Any] | None = None,
    ) -> list[str]:
        chunks = self.chunk(text)
        items = [
            {"text": c, **(metadata or {}), "chunk_index": idx}
            for idx, c in enumerate(chunks)
        ]
        return await self.store.upsert(namespace, items)

    async def retrieve(self, namespace: str, query: str, *, top_k: int = 5) -> RAGResult:
        results = await self.store.search(namespace, query=query, top_k=top_k)
        return RAGResult(chunks=results, namespace=namespace)
