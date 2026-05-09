"""Agents API."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from ..agents import AgentManager, AgentTask
from ..schemas import AgentInfo, AgentRunRequest, AgentRunResult
from .deps import get_agents

router = APIRouter(prefix="/api/agents", tags=["agents"])


@router.get("", response_model=list[AgentInfo])
async def list_agents(agents: AgentManager = Depends(get_agents)) -> list[AgentInfo]:
    return agents.list()


@router.post("/run", response_model=AgentRunResult)
async def run_agent(
    request: AgentRunRequest,
    agents: AgentManager = Depends(get_agents),
) -> AgentRunResult:
    try:
        result = await agents.run(
            request.agent,
            AgentTask(description=request.task, context=request.context),
        )
    except KeyError as exc:
        raise HTTPException(
            status_code=404, detail=f"Unknown agent: {request.agent}"
        ) from exc
    return AgentRunResult(
        agent=result.agent,
        success=result.success,
        output=result.output,
        artifacts=result.artifacts,
        confidence=result.confidence,
    )
