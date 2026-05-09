"""Chat endpoint — runs the full orchestrator pipeline."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from ..core.orchestrator import Orchestrator
from ..schemas import ChatRequest, ChatResponse
from .deps import get_orchestrator

router = APIRouter(prefix="/api/chat", tags=["chat"])


@router.post("", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    orchestrator: Orchestrator = Depends(get_orchestrator),
) -> ChatResponse:
    result = await orchestrator.chat(
        message=request.message,
        session_id=request.session_id,
        project_id=request.project_id,
        agent_hint=request.agent,
        use_memory=request.use_memory,
    )
    return result.response


@router.get("/{session_id}/messages")
async def list_messages(
    session_id: str,
    orchestrator: Orchestrator = Depends(get_orchestrator),
) -> dict:
    history = await orchestrator.memory.recent("conversations", session_id, limit=200)
    return {"session_id": session_id, "messages": history}
