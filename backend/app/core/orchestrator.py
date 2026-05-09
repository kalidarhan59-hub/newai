"""Manus Core Orchestrator — the central plan/route/execute/reflect loop."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any
from uuid import uuid4

from ..agents import AgentManager, AgentTask
from ..memory import MemoryStore
from ..providers import ProviderMessage
from ..schemas import ChatMessage, ChatResponse, Role
from ..tools import ToolManager
from .ai_router import AIRouter, TaskKind
from .context import ContextEngine
from .reasoning import ReasoningEngine
from .task_planner import PlanStep, TaskPlanner

logger = logging.getLogger(__name__)


SYSTEM_PROMPT = (
    "You are Manus Core, a multi-agent AI operating system. "
    "Be precise, structured, and pragmatic. Prefer concrete steps over hedging. "
    "When the user's request is ambiguous, state the most useful interpretation "
    "and proceed."
)


@dataclass
class OrchestratorResult:
    response: ChatResponse
    plan: list[PlanStep]


class Orchestrator:
    """Coordinates planner, router, agents, tools, memory, and reasoning."""

    def __init__(
        self,
        *,
        router: AIRouter,
        agents: AgentManager,
        tools: ToolManager,
        memory: MemoryStore,
        context: ContextEngine,
        reasoning: ReasoningEngine,
        planner: TaskPlanner | None = None,
    ) -> None:
        self.router = router
        self.agents = agents
        self.tools = tools
        self.memory = memory
        self.context = context
        self.reasoning = reasoning
        self.planner = planner or TaskPlanner()

    async def chat(
        self,
        *,
        message: str,
        session_id: str | None = None,
        project_id: str | None = None,
        agent_hint: str | None = None,
        use_memory: bool = True,
    ) -> OrchestratorResult:
        session_id = session_id or str(uuid4())

        # 1. Context
        ctx = await self.context.build(
            session_id=session_id,
            project_id=project_id,
            query=message,
            use_memory=use_memory,
        )

        # 2. Plan
        plan = self.planner.plan(message, agent_hint=agent_hint)
        logger.info("Built plan with %d steps for session %s", len(plan), session_id)

        # 3. Execute
        used_agents: list[str] = []
        intermediate_outputs: list[str] = []
        for step in plan:
            if step.agent:
                used_agents.append(step.agent)
                agent_task = AgentTask(
                    description=step.description,
                    context={
                        "session_id": session_id,
                        "project_id": project_id,
                        "history": ctx.history,
                        "recalled": ctx.recalled,
                        "previous": intermediate_outputs[-3:],
                        "user_message": message,
                    },
                )
                try:
                    result = await self.agents.run(step.agent, agent_task)
                    intermediate_outputs.append(f"[{step.agent}] {result.output}")
                except KeyError:
                    logger.warning("Unknown agent %s — skipping step %d", step.agent, step.id)

        # 4. Final answer (router-level synthesis)
        provider_messages = [
            ProviderMessage(role="system", content=SYSTEM_PROMPT),
        ]
        if ctx.recalled:
            recalled_block = "\n".join(f"- {m.get('text', '')[:300]}" for m in ctx.recalled[:5])
            provider_messages.append(
                ProviderMessage(role="system", content="Relevant memory:\n" + recalled_block)
            )
        for m in ctx.history[-6:]:
            provider_messages.append(
                ProviderMessage(
                    role=m.get("role", "user"),
                    content=m.get("text") or m.get("content") or "",
                )
            )
        if intermediate_outputs:
            provider_messages.append(
                ProviderMessage(
                    role="system",
                    content="Sub-agent outputs to integrate:\n"
                    + "\n\n".join(intermediate_outputs[-5:]),
                )
            )
        provider_messages.append(ProviderMessage(role="user", content=message))

        response = await self.router.complete(
            provider_messages,
            kind=_kind_for_plan(plan),
            temperature=0.3,
            max_tokens=1200,
        )

        # 5. Reflect
        reflection = await self.reasoning.reflect(message, response.text)

        # 6. Persist
        user_msg = ChatMessage(role=Role.USER, content=message)
        assistant_msg = ChatMessage(
            role=Role.ASSISTANT,
            content=reflection.answer,
            metadata={
                "provider": response.provider,
                "model": response.model,
                "confidence": reflection.confidence,
                "critique": reflection.critique,
                "agents": used_agents,
            },
        )
        await self.memory.append(
            "conversations",
            session_id,
            [
                {
                    "id": user_msg.id,
                    "text": user_msg.content,
                    "role": user_msg.role.value,
                },
                {
                    "id": assistant_msg.id,
                    "text": assistant_msg.content,
                    "role": assistant_msg.role.value,
                },
            ],
        )

        return OrchestratorResult(
            response=ChatResponse(
                session_id=session_id,
                message=assistant_msg,
                plan=[_plan_to_dict(s) for s in plan],
                confidence=reflection.confidence,
                used_provider=response.provider,
                used_agents=used_agents,
            ),
            plan=plan,
        )


def _kind_for_plan(plan: list[PlanStep]) -> TaskKind:
    if any(s.kind == TaskKind.CODING for s in plan):
        return TaskKind.CODING
    if any(s.kind == TaskKind.RESEARCH for s in plan):
        return TaskKind.RESEARCH
    if any(s.kind == TaskKind.CREATIVE for s in plan):
        return TaskKind.CREATIVE
    return TaskKind.REASONING


def _plan_to_dict(step: PlanStep) -> dict[str, Any]:
    return {
        "id": step.id,
        "description": step.description,
        "kind": step.kind.value,
        "agent": step.agent,
        "tool": step.tool,
        "depends_on": step.depends_on,
    }
