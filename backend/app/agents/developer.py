"""Developer agent — multi-file coding and architecture."""

from __future__ import annotations

from ..core.ai_router import TaskKind
from .base import AgentResult, AgentTask, BaseAgent


class DeveloperAgent(BaseAgent):
    name = "developer"
    role = "Старший fullstack-инженер"
    description = (
        "Проектирует и внедряет изменения в нескольких файлах на Python и TypeScript. "
        "Предпочитает минимальные патчи с тестами и явные типы."
    )
    capabilities = [
        "fullstack-coding",
        "architecture",
        "multi-file-edits",
        "tests",
        "code-review",
    ]
    task_kind = TaskKind.CODING

    async def run(self, task: AgentTask) -> AgentResult:
        text = await self._ask_llm(task, max_tokens=900)
        return AgentResult(agent=self.name, output=text, confidence=0.7)
