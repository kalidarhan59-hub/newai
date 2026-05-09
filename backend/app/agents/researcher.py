"""Researcher agent — web research and source verification."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class ResearcherAgent(BaseAgent):
    name = "researcher"
    role = "Research lead"
    description = (
        "Performs structured research, cross-checks at least two independent "
        "sources, and produces concise briefs with explicit citations."
    )
    capabilities = ["web-research", "source-verification", "summarisation"]
    task_kind = TaskKind.RESEARCH

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=900)
        return AgentResult(agent=self.name, output=text, confidence=0.65)
