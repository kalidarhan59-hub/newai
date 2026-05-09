"""Tools API."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from ..schemas import ToolCallRequest, ToolCallResult, ToolInfo
from ..tools import ToolManager
from .deps import get_tools

router = APIRouter(prefix="/api/tools", tags=["tools"])


@router.get("", response_model=list[ToolInfo])
async def list_tools(tools: ToolManager = Depends(get_tools)) -> list[ToolInfo]:
    return tools.list()


@router.post("/call", response_model=ToolCallResult)
async def call_tool(
    request: ToolCallRequest,
    tools: ToolManager = Depends(get_tools),
) -> ToolCallResult:
    return await tools.call(request.tool, request.arguments)
