"""Web research convenience endpoint."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from ..tools import ToolManager
from .deps import get_tools

router = APIRouter(prefix="/api/web", tags=["web"])


@router.get("/search")
async def search(q: str, max_results: int = 5, tools: ToolManager = Depends(get_tools)) -> dict:
    result = await tools.call("web_search", {"query": q, "max_results": max_results})
    return result.model_dump()
