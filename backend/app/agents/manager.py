"""Agent registry and dispatcher."""

from __future__ import annotations

from ..core.ai_router import AIRouter
from ..schemas import AgentInfo
from .base import AgentResult, AgentTask, BaseAgent
from .business_analyst import BusinessAnalystAgent
from .debugger import DebuggerAgent
from .designer import DesignerAgent
from .developer import DeveloperAgent
from .pm import ProductManagerAgent
from .presentation import PresentationAgent
from .qa import QAAgent
from .researcher import ResearcherAgent


class AgentManager:
    """Registry and dispatcher for agents."""

    def __init__(self) -> None:
        self._agents: dict[str, BaseAgent] = {}

    def register(self, agent: BaseAgent) -> None:
        self._agents[agent.name] = agent

    def list(self) -> list[AgentInfo]:
        return [
            AgentInfo(
                name=a.name,
                role=a.role,
                description=a.description,
                capabilities=list(a.capabilities),
            )
            for a in self._agents.values()
        ]

    async def run(self, name: str, task: AgentTask) -> AgentResult:
        if name not in self._agents:
            raise KeyError(f"Unknown agent: {name}")
        return await self._agents[name].run(task)


def build_default_agents(router: AIRouter) -> AgentManager:
    manager = AgentManager()
    for cls in (
        DeveloperAgent,
        ResearcherAgent,
        DesignerAgent,
        DebuggerAgent,
        ProductManagerAgent,
        QAAgent,
        PresentationAgent,
        BusinessAnalystAgent,
    ):
        manager.register(cls(router))
    return manager
