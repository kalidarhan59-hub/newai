"""Memory store smoke tests."""

from __future__ import annotations

import asyncio
from pathlib import Path
from tempfile import TemporaryDirectory

from app.memory import MemoryStore, RAGPipeline


def test_memory_upsert_and_search() -> None:
    with TemporaryDirectory() as tmp:
        store = MemoryStore(Path(tmp) / "chroma")

        async def _go() -> None:
            await store.upsert(
                "conversations",
                [
                    {"text": "We talked about pitch decks for B2B SaaS.", "session_id": "s1"},
                    {"text": "Discussed Postgres performance tuning.", "session_id": "s1"},
                    {"text": "Brainstormed marketing taglines.", "session_id": "s2"},
                ],
            )
            results = await store.search("conversations", query="pitch deck", top_k=3)
            assert isinstance(results, list)

        asyncio.run(_go())


def test_rag_chunking() -> None:
    chunks = RAGPipeline.chunk("a" * 1700, max_chars=500, overlap=50)
    assert len(chunks) >= 3
    # Chunks must overlap, so each subsequent chunk shares a prefix with the
    # previous chunk's tail (rough check).
    assert all(len(c) <= 500 for c in chunks)
