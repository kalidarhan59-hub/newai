"""Researcher agent — web research and source verification."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class ResearcherAgent(BaseAgent):
    name = "researcher"
    role = "Руководитель исследований"
    description = (
        "Проводит структурированный ресёрч, сверяет минимум два независимых "
        "источника и выдаёт короткие брифы с явными ссылками."
    )
    capabilities = ["web-research", "source-verification", "summarisation"]
    task_kind = TaskKind.RESEARCH

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=900)
        return AgentResult(agent=self.name, output=text, confidence=0.65)
