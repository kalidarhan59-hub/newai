"""QA agent — test plans, edge cases, regression checklists."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class QAAgent(BaseAgent):
    name = "qa"
    role = "QA lead"
    description = (
        "Designs test plans, enumerates edge cases, and produces regression "
        "checklists. Skeptical by default — prefers reproducible failures."
    )
    capabilities = ["test-plans", "edge-cases", "regression-checklists"]
    task_kind = TaskKind.REASONING

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=700)
        return AgentResult(agent=self.name, output=text, confidence=0.7)
