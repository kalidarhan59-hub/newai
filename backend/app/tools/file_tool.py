"""File system tools scoped to the upload workspace."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from .base import BaseTool


class _WorkspaceTool(BaseTool):
    def __init__(self, root: Path) -> None:
        self.root = root

    def _resolve(self, name: str) -> Path:
        candidate = (self.root / name).resolve()
        root = self.root.resolve()
        if not str(candidate).startswith(str(root)):
            raise ValueError("path escapes the workspace")
        return candidate


class FileReadTool(_WorkspaceTool):
    name = "file_read"
    description = "Прочитать файл из рабочего пространства по имени."
    schema = {
        "type": "object",
        "properties": {"name": {"type": "string"}},
        "required": ["name"],
    }

    async def call(self, arguments: dict[str, Any]) -> dict[str, Any]:
        name = str(arguments["name"])
        path = self._resolve(name)
        if not path.exists():
            return {"content": "", "exists": False}
        return {"content": path.read_text(errors="replace"), "exists": True}


class FileWriteTool(_WorkspaceTool):
    name = "file_write"
    description = "Записать файл в рабочее пространство по имени."
    schema = {
        "type": "object",
        "properties": {
            "name": {"type": "string"},
            "content": {"type": "string"},
        },
        "required": ["name", "content"],
    }

    async def call(self, arguments: dict[str, Any]) -> dict[str, Any]:
        name = str(arguments["name"])
        content = str(arguments["content"])
        path = self._resolve(name)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return {"written": str(path), "size": len(content)}


class ParseFileTool(_WorkspaceTool):
    name = "parse_file"
    description = "Разобрать файл из рабочего пространства и вернуть чанки + выжимку."
    schema = {
        "type": "object",
        "properties": {"name": {"type": "string"}},
        "required": ["name"],
    }

    async def call(self, arguments: dict[str, Any]) -> dict[str, Any]:
        from ..files.parser import parse_path

        name = str(arguments["name"])
        path = self._resolve(name)
        if not path.exists():
            return {"error": "not found", "name": name}
        doc = parse_path(path)
        return doc.model_dump()
