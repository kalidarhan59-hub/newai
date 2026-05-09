"""Base classes for tools."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any


class BaseTool(ABC):
    name: str = "base"
    description: str = ""
    schema: dict[str, Any] = {"type": "object", "properties": {}, "required": []}

    @abstractmethod
    async def call(self, arguments: dict[str, Any]) -> Any: ...
