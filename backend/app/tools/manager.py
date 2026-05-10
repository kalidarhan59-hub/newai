"""Tool registry and dispatcher."""

from __future__ import annotations

from typing import Any

from ..config import Settings
from ..schemas import ToolCallResult, ToolInfo
from .base import BaseTool
from .code_exec import CodeExecTool
from .file_tool import FileReadTool, FileWriteTool, ParseFileTool
from .music_producer import MusicProducerTool
from .terminal import TerminalTool
from .web_search import WebSearchTool


class ToolManager:
    def __init__(self) -> None:
        self._tools: dict[str, BaseTool] = {}

    def register(self, tool: BaseTool) -> None:
        self._tools[tool.name] = tool

    def list(self) -> list[ToolInfo]:
        return [
            ToolInfo.model_validate(
                {"name": t.name, "description": t.description, "schema": t.schema}
            )
            for t in self._tools.values()
        ]

    async def call(self, name: str, arguments: dict[str, Any]) -> ToolCallResult:
        tool = self._tools.get(name)
        if tool is None:
            return ToolCallResult(tool=name, success=False, output=None, error="unknown tool")
        try:
            output = await tool.call(arguments)
            return ToolCallResult(tool=name, success=True, output=output)
        except Exception as e:
            return ToolCallResult(tool=name, success=False, output=None, error=str(e))


def build_default_tools(settings: Settings) -> ToolManager:
    manager = ToolManager()
    manager.register(WebSearchTool(api_key=settings.tavily_api_key))
    manager.register(TerminalTool())
    manager.register(CodeExecTool())
    manager.register(FileReadTool(root=settings.upload_dir))
    manager.register(FileWriteTool(root=settings.upload_dir))
    manager.register(ParseFileTool(root=settings.upload_dir))
    manager.register(MusicProducerTool())
    return manager
