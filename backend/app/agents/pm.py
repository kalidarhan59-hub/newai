"""Product manager agent — roadmaps, requirements, user stories."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class ProductManagerAgent(BaseAgent):
    name = "pm"
    role = "Product manager"
    description = (
        "Translates fuzzy requests into clear requirements, user stories, and "
        "phased roadmaps. Calls out unknowns before committing to a plan."
    )
    capabilities = ["requirements", "roadmaps", "user-stories", "scoping"]
    task_kind = TaskKind.REASONING

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=800)
        return AgentResult(agent=self.name, output=text, confidence=0.65)
