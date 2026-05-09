"""Pydantic schemas shared across API and core modules."""

from __future__ import annotations

from datetime import UTC, datetime
from enum import StrEnum
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field

# ---------------------------------------------------------------------------
# Chat
# ---------------------------------------------------------------------------


class Role(StrEnum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"
    TOOL = "tool"


class ChatMessage(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    role: Role
    content: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    metadata: dict[str, Any] = Field(default_factory=dict)


class ChatRequest(BaseModel):
    message: str
    session_id: str | None = None
    project_id: str | None = None
    agent: str | None = None
    use_memory: bool = True


class ChatResponse(BaseModel):
    session_id: str
    message: ChatMessage
    plan: list[dict[str, Any]] = Field(default_factory=list)
    confidence: float = 0.0
    used_provider: str = "mock"
    used_agents: list[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Agents
# ---------------------------------------------------------------------------


class AgentInfo(BaseModel):
    name: str
    role: str
    description: str
    capabilities: list[str] = Field(default_factory=list)


class AgentRunRequest(BaseModel):
    agent: str
    task: str
    context: dict[str, Any] = Field(default_factory=dict)


class AgentRunResult(BaseModel):
    agent: str
    success: bool
    output: str
    artifacts: list[dict[str, Any]] = Field(default_factory=list)
    confidence: float = 0.0


# ---------------------------------------------------------------------------
# Files
# ---------------------------------------------------------------------------


class ParsedDocument(BaseModel):
    file_id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    content_type: str
    summary: str
    chunks: list[str]
    metadata: dict[str, Any] = Field(default_factory=dict)


class FileInfo(BaseModel):
    file_id: str
    name: str
    size: int
    content_type: str
    uploaded_at: datetime


# ---------------------------------------------------------------------------
# Projects
# ---------------------------------------------------------------------------


class Project(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    description: str = ""
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))
    tags: list[str] = Field(default_factory=list)


class ProjectCreate(BaseModel):
    name: str
    description: str = ""
    tags: list[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Memory
# ---------------------------------------------------------------------------


class MemoryEntry(BaseModel):
    id: str
    text: str
    score: float
    metadata: dict[str, Any] = Field(default_factory=dict)


class MemorySearchRequest(BaseModel):
    query: str
    top_k: int = 5
    namespace: str = "conversations"


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------


class ToolInfo(BaseModel):
    model_config = {"populate_by_name": True, "protected_namespaces": ()}

    name: str
    description: str
    json_schema: dict[str, Any] = Field(default_factory=dict, alias="schema")


class ToolCallRequest(BaseModel):
    tool: str
    arguments: dict[str, Any] = Field(default_factory=dict)


class ToolCallResult(BaseModel):
    tool: str
    success: bool
    output: Any
    error: str | None = None
