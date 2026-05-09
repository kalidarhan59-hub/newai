"""Business analyst agent — market sizing, competition, GTM."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class BusinessAnalystAgent(BaseAgent):
    name = "business_analyst"
    role = "Бизнес-аналитик"
    description = (
        "Считает размер рынка, анализирует конкурентов и строит план выхода на рынок. "
        "Квантифицирует допущения и помечает слабые данные."
    )
    capabilities = ["market-sizing", "competitor-analysis", "gtm", "pricing"]
    task_kind = TaskKind.REASONING

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=900)
        return AgentResult(agent=self.name, output=text, confidence=0.65)
