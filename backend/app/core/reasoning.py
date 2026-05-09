"""Reasoning engine — chain-of-thought, tree-of-thought, self-check."""

from __future__ import annotations

from dataclasses import dataclass

from ..providers import ProviderMessage
from .ai_router import AIRouter, TaskKind


@dataclass
class ReasoningResult:
    answer: str
    confidence: float
    critique: str


SELF_CHECK_PROMPT = (
    "Ты — строгий критик. Прочитай ответ ниже и верни JSON-объект "
    "в формате: {\"confidence\": <0..1>, \"critique\": <одно предложение на русском>}. "
    "Будь строг: штрафуй галлюцинации, пропущенные ограничения и "
    "неподкреплённые утверждения."
)


class ReasoningEngine:
    """Wraps a provider with self-check and naive confidence estimation.

    The engine is intentionally small in the MVP. It exposes the extension
    points (CoT, ToT, self-check) so they can be hardened later, without
    pretending to ship a research-grade reasoner.
    """

    def __init__(self, router: AIRouter) -> None:
        self.router = router

    async def reflect(self, question: str, answer: str) -> ReasoningResult:
        """Run a single self-critique pass over an existing answer."""

        critique_prompt = (
            f"ВОПРОС:\n{question}\n\nОТВЕТ:\n{answer}\n\n"
            "Ответь ТОЛЬКО описанным JSON-объектом."
        )
        response = await self.router.complete(
            [
                ProviderMessage(role="system", content=SELF_CHECK_PROMPT),
                ProviderMessage(role="user", content=critique_prompt),
            ],
            kind=TaskKind.REASONING,
            temperature=0.0,
            max_tokens=200,
        )
        return _parse_critique(answer, response.text)


def _parse_critique(answer: str, raw: str) -> ReasoningResult:
    """Best-effort JSON parse with a heuristic fallback."""

    import json
    import re

    confidence = 0.6
    critique = "Критика mock-провайдера: структура выглядит согласованно."

    match = re.search(r"\{[^{}]*\}", raw)
    if match:
        try:
            data = json.loads(match.group(0))
            if isinstance(data.get("confidence"), (int, float)):
                confidence = max(0.0, min(1.0, float(data["confidence"])))
            if isinstance(data.get("critique"), str):
                critique = data["critique"]
        except json.JSONDecodeError:
            pass
    else:
        # Heuristic: longer, more structured answers get a small confidence
        # bump. Hedging language drops it.
        score = 0.5 + min(0.3, len(answer) / 4000)
        if any(w in answer.lower() for w in ("might", "maybe", "i think", "possibly")):
            score -= 0.1
        confidence = max(0.0, min(1.0, score))

    return ReasoningResult(answer=answer, confidence=confidence, critique=critique)
