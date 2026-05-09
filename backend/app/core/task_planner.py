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
                    "Прочитать релевантные файлы и проанализировать кодовую базу.",
                    TaskKind.CODING,
                    agent="developer",
                ),
                PlanStep(
                    2,
                    "Предложить минимальный патч.",
                    TaskKind.CODING,
                    agent="developer",
                    depends_on=[1],
                ),
                PlanStep(
                    3,
                    "Добавить или обновить тесты.",
                    TaskKind.CODING,
                    agent="qa",
                    depends_on=[2],
                ),
                PlanStep(
                    4,
                    "Кратко описать диф для пользователя.",
                    TaskKind.GENERAL,
                    depends_on=[3],
                ),
            ]
        if intent == "research":
            return [
                PlanStep(
                    1,
                    "Провести веб-исследование по теме.",
                    TaskKind.RESEARCH,
                    agent="researcher",
                    tool="web_search",
                ),
                PlanStep(
                    2,
                    "Сверить минимум два независимых источника.",
                    TaskKind.RESEARCH,
                    agent="researcher",
                    depends_on=[1],
                ),
                PlanStep(
                    3,
                    "Свести находки в краткий бриф.",
                    TaskKind.GENERAL,
                    agent="researcher",
                    depends_on=[2],
                ),
            ]
        if intent == "design":
            return [
                PlanStep(
                    1,
                    "Уточнить целевого пользователя и ключевую задачу.",
                    TaskKind.CREATIVE,
                    agent="designer",
                ),
                PlanStep(
                    2,
                    "Набросать информационную архитектуру.",
                    TaskKind.CREATIVE,
                    agent="designer",
                    depends_on=[1],
                ),
                PlanStep(
                    3,
                    "Подготовить визуальную спецификацию под Tailwind.",
                    TaskKind.CREATIVE,
                    agent="designer",
                    depends_on=[2],
                ),
            ]
        if intent == "business":
            return [
                PlanStep(
                    1,
                    "Сформулировать проблему и рынок.",
                    TaskKind.RESEARCH,
                    agent="business_analyst",
                ),
                PlanStep(
                    2,
                    "Прописать ценностное предложение и конкурентов.",
                    TaskKind.REASONING,
                    agent="business_analyst",
                    depends_on=[1],
                ),
                PlanStep(
                    3,
                    "Набросать структуру pitch deck.",
                    TaskKind.CREATIVE,
                    agent="presentation",
                    depends_on=[2],
                ),
                PlanStep(
                    4,
                    "QA-проход на согласованность нарратива.",
                    TaskKind.REASONING,
                    agent="qa",
                    depends_on=[3],
                ),
            ]
        return [
            PlanStep(
                1,
                "Понять запрос и ключевые ограничения.",
                TaskKind.REASONING,
                agent="pm",
            ),
            PlanStep(
                2,
                "Выполнить наиболее вероятную интерпретацию.",
                TaskKind.GENERAL,
                agent="developer",
                depends_on=[1],
            ),
            PlanStep(
                3,
                "Сделать self-check и собрать финальный ответ.",
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
    code_kw = (
        "code", "bug", "stack trace", "function", "class ", "typescript", "python",
        "код", "баг", "ошибк", "функци", "класс", "тайпскрипт", "питон", "патч",
    )
    research_kw = (
        "research", "find", "compare", "competitor", "paper", "article", "search",
        "исследов", "найди", "найти", "сравни", "конкурент", "статья", "источник", "поиск",
    )
    design_kw = (
        "design", " ui", " ux", "figma", "layout", "component",
        "дизайн", "интерфейс", "макет", "компонент",
    )
    business_kw = (
        "startup", "market", "business", "investor", "pitch", "revenue", "saas",
        "стартап", "рынок", "бизнес", "инвестор", "питч", "выручк",
    )
    if any(k in t for k in code_kw):
        return "code"
    if any(k in t for k in research_kw):
        return "research"
    if any(k in t for k in design_kw):
        return "design"
    if any(k in t for k in business_kw):
        return "business"
    return "general"
