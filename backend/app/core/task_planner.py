"""Decomposes a user request into a typed plan of executable steps."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from .ai_router import TaskKind


@dataclass
class PlanStep:
    """A single step in a multi-step plan."""

    id: int
    description: str
    kind: TaskKind = TaskKind.GENERAL
    agent: str | None = None
    tool: str | None = None
    inputs: dict[str, Any] = field(default_factory=dict)
    depends_on: list[int] = field(default_factory=list)


class TaskPlanner:
    """Heuristic planner used by the orchestrator.

    The MVP implementation classifies the request using a small set of keyword
    rules and returns a 2-4 step plan. The contract is intentionally identical
    to a future LLM-driven planner so it can be swapped in without touching
    callers.
    """

    def plan(self, request: str, *, agent_hint: str | None = None) -> list[PlanStep]:
        intent = _classify(request)
        if agent_hint:
            return self._single_agent_plan(request, agent_hint, intent)

        if intent == "code":
            return [
                PlanStep(
                    1,
                    "Read relevant files and analyse the codebase.",
                    TaskKind.CODING,
                    agent="developer",
                ),
                PlanStep(
                    2,
                    "Propose a minimal patch.",
                    TaskKind.CODING,
                    agent="developer",
                    depends_on=[1],
                ),
                PlanStep(3, "Add or update tests.", TaskKind.CODING, agent="qa", depends_on=[2]),
                PlanStep(
                    4,
                    "Summarise the diff for the user.",
                    TaskKind.GENERAL,
                    depends_on=[3],
                ),
            ]
        if intent == "research":
            return [
                PlanStep(
                    1,
                    "Run web research on the topic.",
                    TaskKind.RESEARCH,
                    agent="researcher",
                    tool="web_search",
                ),
                PlanStep(
                    2,
                    "Cross-check at least two sources.",
                    TaskKind.RESEARCH,
                    agent="researcher",
                    depends_on=[1],
                ),
                PlanStep(
                    3,
                    "Synthesise findings into a brief.",
                    TaskKind.GENERAL,
                    agent="researcher",
                    depends_on=[2],
                ),
            ]
        if intent == "design":
            return [
                PlanStep(
                    1,
                    "Clarify the user persona and primary task.",
                    TaskKind.CREATIVE,
                    agent="designer",
                ),
                PlanStep(
                    2,
                    "Sketch information architecture.",
                    TaskKind.CREATIVE,
                    agent="designer",
                    depends_on=[1],
                ),
                PlanStep(
                    3,
                    "Produce a Tailwind-friendly visual spec.",
                    TaskKind.CREATIVE,
                    agent="designer",
                    depends_on=[2],
                ),
            ]
        if intent == "business":
            return [
                PlanStep(
                    1,
                    "Frame problem and market.",
                    TaskKind.RESEARCH,
                    agent="business_analyst",
                ),
                PlanStep(
                    2,
                    "Outline value proposition and competition.",
                    TaskKind.REASONING,
                    agent="business_analyst",
                    depends_on=[1],
                ),
                PlanStep(
                    3,
                    "Draft pitch deck outline.",
                    TaskKind.CREATIVE,
                    agent="presentation",
                    depends_on=[2],
                ),
                PlanStep(
                    4,
                    "QA pass for narrative consistency.",
                    TaskKind.REASONING,
                    agent="qa",
                    depends_on=[3],
                ),
            ]
        return [
            PlanStep(
                1,
                "Understand the request and key constraints.",
                TaskKind.REASONING,
                agent="pm",
            ),
            PlanStep(
                2,
                "Execute the most likely interpretation.",
                TaskKind.GENERAL,
                agent="developer",
                depends_on=[1],
            ),
            PlanStep(
                3,
                "Self-check and produce a final answer.",
                TaskKind.REASONING,
                agent="qa",
                depends_on=[2],
            ),
        ]

    @staticmethod
    def _single_agent_plan(request: str, agent: str, intent: str) -> list[PlanStep]:
        kind = {
            "code": TaskKind.CODING,
            "research": TaskKind.RESEARCH,
            "design": TaskKind.CREATIVE,
            "business": TaskKind.REASONING,
        }.get(intent, TaskKind.GENERAL)
        return [PlanStep(1, request, kind, agent=agent)]


def _classify(text: str) -> str:
    t = text.lower()
    if any(k in t for k in ("code", "bug", "stack trace", "function", "class ", "typescript", "python")):
        return "code"
    if any(k in t for k in ("research", "find", "compare", "competitor", "paper", "article", "search")):
        return "research"
    if any(k in t for k in ("design", " ui", " ux", "figma", "layout", "component")):
        return "design"
    if any(k in t for k in ("startup", "market", "business", "investor", "pitch", "revenue", "saas")):
        return "business"
    return "general"
