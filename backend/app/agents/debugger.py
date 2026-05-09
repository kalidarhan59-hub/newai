"""Debugger agent — log triage and bug analysis."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class DebuggerAgent(BaseAgent):
    name = "debugger"
    role = "Production debugger"
    description = (
        "Reads stack traces and logs, isolates the failing component, and "
        "proposes the smallest possible fix plus a regression test."
    )
    capabilities = ["log-analysis", "stack-traces", "fix-proposals"]
    task_kind = TaskKind.CODING

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=800)
        return AgentResult(agent=self.name, output=text, confidence=0.7)
