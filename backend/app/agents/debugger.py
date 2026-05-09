"""Debugger agent — log triage and bug analysis."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class DebuggerAgent(BaseAgent):
    name = "debugger"
    role = "Инженер по отладке production-инцидентов"
    description = (
        "Читает stack trace и логи, локализует падающий компонент и предлагает "
        "минимально возможный фикс и регресс-тест к нему."
    )
    capabilities = ["log-analysis", "stack-traces", "fix-proposals"]
    task_kind = TaskKind.CODING

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=800)
        return AgentResult(agent=self.name, output=text, confidence=0.7)
