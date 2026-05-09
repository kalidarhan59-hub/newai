"""Designer agent — UI/UX briefs and component sketches."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class DesignerAgent(BaseAgent):
    name = "designer"
    role = "Product designer"
    description = (
        "Produces UI/UX briefs, information architecture, and Tailwind-friendly "
        "component sketches. Optimises for legibility and progressive disclosure."
    )
    capabilities = ["ui", "ux", "component-design", "design-spec"]
    task_kind = TaskKind.CREATIVE

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=800)
        return AgentResult(agent=self.name, output=text, confidence=0.65)
