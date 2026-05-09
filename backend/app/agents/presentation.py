"""Presentation agent — pitch decks and slide narratives."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class PresentationAgent(BaseAgent):
    name = "presentation"
    role = "Специалист по презентациям для инвесторов"
    description = (
        "Собирает pitch deck инвесторского уровня: проблема, рынок, решение, трекшн, "
        "команда, финансы, ask. Один слайд — одна мысль."
    )
    capabilities = ["pitch-deck", "narrative", "slide-content"]
    task_kind = TaskKind.CREATIVE

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=900)
        return AgentResult(agent=self.name, output=text, confidence=0.65)
