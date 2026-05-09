"""Memory API."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from ..memory import MemoryStore
from ..schemas import MemoryEntry, MemorySearchRequest
from .deps import get_memory

router = APIRouter(prefix="/api/memory", tags=["memory"])


@router.post("/search", response_model=list[MemoryEntry])
async def search(
    request: MemorySearchRequest,
    memory: MemoryStore = Depends(get_memory),
) -> list[MemoryEntry]:
    results = await memory.search(request.namespace, query=request.query, top_k=request.top_k)
    return [
        MemoryEntry(
            id=str(r.get("id", "")),
            text=str(r.get("text", "")),
            score=float(r.get("score", 0.0)),
            metadata={k: v for k, v in r.items() if k not in ("id", "text", "score")},
        )
        for r in results
    ]


@router.get("/{namespace}", response_model=list[MemoryEntry])
async def list_namespace(
    namespace: str,
    limit: int = 50,
    memory: MemoryStore = Depends(get_memory),
) -> list[MemoryEntry]:
    results = await memory.list_namespace(namespace, limit=limit)
    return [
        MemoryEntry(
            id=str(r.get("id", "")),
            text=str(r.get("text", "")),
            score=0.0,
            metadata={k: v for k, v in r.items() if k not in ("id", "text", "score")},
        )
        for r in results
    ]
