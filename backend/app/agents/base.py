"""Base classes for the multi-agent system."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any

from ..core.ai_router import AIRouter, TaskKind
from ..providers import ProviderMessage


@dataclass
class AgentTask:
    description: str
    context: dict[str, Any] = field(default_factory=dict)


@dataclass
class AgentResult:
    agent: str
    output: str
    success: bool = True
    artifacts: list[dict[str, Any]] = field(default_factory=list)
    confidence: float = 0.0


class BaseAgent(ABC):
    """All agents inherit from this class."""

    name: str = "base"
    role: str = "generic specialist"
    description: str = ""
    capabilities: list[str] = []
    task_kind: TaskKind = TaskKind.GENERAL

    def __init__(self, router: AIRouter) -> None:
        self.router = router

    @property
    def system_prompt(self) -> str:
        return (
            f"You are {self.role} (codename {self.name}). "
            f"{self.description} "
            "Operate as part of Manus Core, a multi-agent AI platform. "
            "Be specific, structured, and actionable. Cite assumptions explicitly."
        )

    @abstractmethod
    async def run(self, task: AgentTask) -> AgentResult: ...

    async def _ask_llm(self, task: AgentTask, *, max_tokens: int = 800) -> str:
        prior = task.context.get("previous") or []
        prior_block = "\n".join(prior[-3:]) if prior else "(no prior steps)"
        user_block = (
            f"Task:\n{task.description}\n\n"
            f"User message:\n{task.context.get('user_message', '')}\n\n"
            f"Prior step outputs:\n{prior_block}"
        )
        response = await self.router.complete(
            [
                ProviderMessage(role="system", content=self.system_prompt),
                ProviderMessage(role="user", content=user_block),
            ],
            kind=self.task_kind,
            temperature=0.3,
            max_tokens=max_tokens,
        )
        return response.text
