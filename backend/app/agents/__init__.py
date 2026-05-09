"""Multi-agent system."""

from .base import AgentResult, AgentTask, BaseAgent
from .manager import AgentManager, build_default_agents

__all__ = [
    "AgentManager",
    "AgentResult",
    "AgentTask",
    "BaseAgent",
    "build_default_agents",
]
