"""FastAPI dependency wiring — exposes the orchestrator and friends to routes."""

from __future__ import annotations

from functools import lru_cache

from ..agents import AgentManager, build_default_agents
from ..config import Settings, get_settings
from ..core import AIRouter, ContextEngine, ReasoningEngine, TaskPlanner
from ..core.orchestrator import Orchestrator
from ..memory import MemoryStore, RAGPipeline
from ..projects import ProjectService
from ..providers import build_default_providers
from ..tools import ToolManager, build_default_tools


@lru_cache(maxsize=1)
def _build_app_state() -> dict[str, object]:
    settings: Settings = get_settings()
    providers = build_default_providers()
    router = AIRouter(providers)
    memory = MemoryStore(settings.chroma_dir)
    rag = RAGPipeline(memory)
    context = ContextEngine(memory)
    reasoning = ReasoningEngine(router)
    agents = build_default_agents(router)
    tools = build_default_tools(settings)
    projects = ProjectService(settings.data_dir)
    orchestrator = Orchestrator(
        router=router,
        agents=agents,
        tools=tools,
        memory=memory,
        context=context,
        reasoning=reasoning,
        planner=TaskPlanner(),
    )
    return {
        "settings": settings,
        "router": router,
        "memory": memory,
        "rag": rag,
        "agents": agents,
        "tools": tools,
        "projects": projects,
        "orchestrator": orchestrator,
    }


def get_orchestrator() -> Orchestrator:
    return _build_app_state()["orchestrator"]  # type: ignore[return-value]


def get_router_dep() -> AIRouter:
    return _build_app_state()["router"]  # type: ignore[return-value]


def get_memory() -> MemoryStore:
    return _build_app_state()["memory"]  # type: ignore[return-value]


def get_rag() -> RAGPipeline:
    return _build_app_state()["rag"]  # type: ignore[return-value]


def get_agents() -> AgentManager:
    return _build_app_state()["agents"]  # type: ignore[return-value]


def get_tools() -> ToolManager:
    return _build_app_state()["tools"]  # type: ignore[return-value]


def get_projects() -> ProjectService:
    return _build_app_state()["projects"]  # type: ignore[return-value]
