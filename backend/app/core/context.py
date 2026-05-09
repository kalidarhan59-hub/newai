"""Context engine — assembles the working context for a request."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from ..memory import MemoryStore


@dataclass
class WorkingContext:
    session_id: str
    project_id: str | None
    history: list[dict[str, Any]] = field(default_factory=list)
    recalled: list[dict[str, Any]] = field(default_factory=list)
    profile: dict[str, Any] = field(default_factory=dict)


class ContextEngine:
    """Pulls together the relevant context for a single user request."""

    def __init__(self, memory: MemoryStore) -> None:
        self.memory = memory

    async def build(
        self,
        *,
        session_id: str,
        project_id: str | None,
        query: str,
        use_memory: bool = True,
    ) -> WorkingContext:
        history = await self.memory.recent("conversations", session_id, limit=10)
        recalled: list[dict[str, Any]] = []
        if use_memory:
            recalled = await self.memory.search(
                "conversations",
                query=query,
                top_k=5,
                where={"session_id": session_id} if session_id else None,
            )
        profile = await self.memory.get_profile(session_id)
        return WorkingContext(
            session_id=session_id,
            project_id=project_id,
            history=history,
            recalled=recalled,
            profile=profile,
        )

    @staticmethod
    def to_provider_messages(context: WorkingContext, query: str, system_prompt: str) -> list[dict[str, str]]:
        messages: list[dict[str, str]] = [{"role": "system", "content": system_prompt}]
        if context.recalled:
            recalled_block = "\n".join(f"- {m.get('text', '')[:300]}" for m in context.recalled[:5])
            messages.append(
                {
                    "role": "system",
                    "content": "Relevant memory:\n" + recalled_block,
                }
            )
        for m in context.history[-6:]:
            role = m.get("role", "user")
            content = m.get("text") or m.get("content") or ""
            if role in ("user", "assistant", "system"):
                messages.append({"role": role, "content": content})
        messages.append({"role": "user", "content": query})
        return messages
