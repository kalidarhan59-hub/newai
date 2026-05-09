"""Product manager agent — roadmaps, requirements, user stories."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class ProductManagerAgent(BaseAgent):
    name = "pm"
    role = "Продакт-менеджер"
    description = (
        "Переводит размытые запросы в чёткие требования, user stories и "
        "этапные roadmap-ы. Явно фиксирует неизвестные до фиксации плана."
    )
    capabilities = ["requirements", "roadmaps", "user-stories", "scoping"]
    task_kind = TaskKind.REASONING

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=800)
        return AgentResult(agent=self.name, output=text, confidence=0.65)
