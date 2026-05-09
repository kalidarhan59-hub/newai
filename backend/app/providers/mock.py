"""Deterministic mock provider used when no real LLM credentials are present."""

from __future__ import annotations

import hashlib

from .base import BaseProvider, ProviderMessage, ProviderResponse


class MockProvider(BaseProvider):
    """A deterministic provider that produces plausible structured responses.

    The mock is used in three situations:

    * Local development without API keys.
    * CI / unit tests, where determinism is required.
    * Graceful degradation when a real provider returns an error.
    """

    name = "mock"
    default_model = "mock-1"

    def __init__(self) -> None:
        super().__init__()
        self.available = True

    async def complete(
        self,
        messages: list[ProviderMessage],
        *,
        model: str | None = None,
        temperature: float = 0.3,
        max_tokens: int = 1024,
    ) -> ProviderResponse:
        last_user = next(
            (m.content for m in reversed(messages) if m.role == "user"),
            "",
        )
        system_hint = next(
            (m.content for m in messages if m.role == "system"),
            "",
        )
        text = _format_mock_response(last_user, system_hint)
        return ProviderResponse(
            text=text,
            provider=self.name,
            model=model or self.default_model,
            usage={"prompt_tokens": len(last_user), "completion_tokens": len(text)},
            raw={"deterministic": True},
        )


def _format_mock_response(user_message: str, system_hint: str) -> str:
    """Produce a structured mock answer with reasoning + plan + final answer."""

    seed = hashlib.sha256((system_hint + "::" + user_message).encode("utf-8")).hexdigest()[:8]
    intent = _classify_intent(user_message)

    plan_steps: dict[str, list[str]] = {
        "code": [
            "Изучить релевантные файлы в рабочем пространстве.",
            "Набросать изменение на уровне функций.",
            "Применить изменение и запустить тесты.",
            "Кратко описать диф для пользователя.",
        ],
        "research": [
            "Сформулировать главный вопрос и подвопросы.",
            "Подтянуть авторитетные источники через web-инструмент.",
            "Сверить минимум два независимых источника.",
            "Свести находки в структурированный бриф.",
        ],
        "design": [
            "Уточнить целевого пользователя и его задачу.",
            "Набросать информационную архитектуру.",
            "Предложить взаимодействия на уровне компонентов.",
            "Дать визуальную спецификацию под Tailwind.",
        ],
        "business": [
            "Сформулировать проблему и целевой рынок.",
            "Оценить размер рынка и ключевых конкурентов.",
            "Прописать ценностное предложение и моат.",
            "Набросать модель выхода на рынок и ценообразование.",
        ],
        "general": [
            "Переформулировать цель в конкретных терминах.",
            "Разбить её на 2–4 атомарные подзадачи.",
            "Выполнить каждую подзадачу и проверить.",
            "Собрать структурированный финальный ответ.",
        ],
    }
    intent_labels: dict[str, str] = {
        "code": "код",
        "research": "исследование",
        "design": "дизайн",
        "business": "бизнес",
        "general": "общая задача",
    }
    steps = plan_steps.get(intent, plan_steps["general"])
    intent_label = intent_labels.get(intent, intent_labels["general"])

    plan_block = "\n".join(f"  {i+1}. {s}" for i, s in enumerate(steps))
    return (
        f"[mock:{seed}] Manus Core принял ваш запрос"
        + (f" с системным контекстом «{_truncate(system_hint, 80)}»" if system_hint else "")
        + ".\n\n"
        + "Рассуждение (chain-of-thought, кратко):\n"
        + f"  • интент → {intent_label}\n"
        + f"  • длина ввода → {len(user_message)} символов\n"
        + f"  • выбранный плейбук → {intent}-playbook\n\n"
        + "План:\n"
        + plan_block
        + "\n\nЧерновой ответ:\n"
        + _draft_answer(user_message, intent)
        + "\n\n"
        + "(Это детерминированный ответ от Mock-провайдера. Добавьте "
        + "ANTHROPIC_API_KEY / OPENAI_API_KEY / GOOGLE_API_KEY в backend/.env, "
        + "чтобы переключиться на реальную модель.)"
    )


def _classify_intent(text: str) -> str:
    t = text.lower()
    code_kw = (
        "code", "bug", "stack trace", "function", "class ", "typescript", "python",
        "код", "баг", "ошибк", "функци", "класс", "тайпскрипт", "питон", "патч",
    )
    research_kw = (
        "research", "find", "compare", "competitor", "paper", "article",
        "исследов", "найди", "найти", "сравни", "конкурент", "статья", "источник",
    )
    design_kw = (
        "design", "ui", "ux", "figma", "layout", "component",
        "дизайн", "интерфейс", "макет", "компонент",
    )
    business_kw = (
        "startup", "market", "business", "investor", "pitch", "revenue",
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


def _draft_answer(user_message: str, intent: str) -> str:
    short = _truncate(user_message, 220)
    if intent == "code":
        return (
            f"Для запроса «{short}» рекомендуемый подход — добавить небольшой,"
            " самодостаточный модуль с явными типами, интеграционным тестом и"
            " коротким docstring, описывающим контракт."
        )
    if intent == "research":
        return (
            f"Главные тезисы по «{short}»: (i) область быстро меняется, ожидайте"
            " breaking-изменений; (ii) считайте любой одиночный источник гипотезой,"
            " пока он не подтверждён; (iii) приоритет — первичные источники и"
            " свежие обзоры."
        )
    if intent == "design":
        return (
            f"Для «{short}» оптимизируйте читаемость с первого взгляда: 12-колоночная"
            " сетка, один акцентный цвет и прогрессивное раскрытие для продвинутых"
            " контролов."
        )
    if intent == "business":
        return (
            f"Для «{short}» сформулируйте «клин» в одном предложении, проверьте его"
            " на 5–7 интервью с клиентами и заложите цену под минимально жизнеспособную"
            " когорту, прежде чем расширять рынок."
        )
    return (
        f"Принято: «{short}». Manus Core выполнит план выше и будет"
        " транслировать промежуточные результаты в чат по мере выполнения подзадач."
    )


def _truncate(text: str, limit: int) -> str:
    text = " ".join(text.split())
    return text if len(text) <= limit else text[: limit - 1] + "…"


__all__ = ["MockProvider"]
