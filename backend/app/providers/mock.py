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
            "Inspect the relevant files in the workspace.",
            "Sketch the change at the function level.",
            "Apply the change and run the test suite.",
            "Summarise the diff for the user.",
        ],
        "research": [
            "Identify the core question and sub-questions.",
            "Pull authoritative sources via the web tool.",
            "Cross-check at least two independent sources.",
            "Synthesise findings into a structured brief.",
        ],
        "design": [
            "Clarify the user persona and primary task.",
            "Sketch the information architecture.",
            "Propose component-level interactions.",
            "Provide a Tailwind-friendly visual spec.",
        ],
        "business": [
            "Frame the problem and target market.",
            "Estimate market size and key competitors.",
            "Outline the value proposition and moat.",
            "Draft a go-to-market and pricing model.",
        ],
        "general": [
            "Restate the goal in concrete terms.",
            "Break it into 2-4 atomic sub-tasks.",
            "Execute each sub-task and verify.",
            "Compose a structured final answer.",
        ],
    }
    steps = plan_steps.get(intent, plan_steps["general"])

    plan_block = "\n".join(f"  {i+1}. {s}" for i, s in enumerate(steps))
    return (
        f"[mock:{seed}] Manus Core received your request"
        + (f" with system context \"{_truncate(system_hint, 80)}\"" if system_hint else "")
        + ".\n\n"
        + "Reasoning (chain-of-thought, abbreviated):\n"
        + f"  • intent → {intent}\n"
        + f"  • input length → {len(user_message)} chars\n"
        + f"  • selected playbook → {intent}-playbook\n\n"
        + "Plan:\n"
        + plan_block
        + "\n\nDraft answer:\n"
        + _draft_answer(user_message, intent)
        + "\n\n"
        + "(This deterministic answer comes from the Mock provider. Add an "
        + "ANTHROPIC_API_KEY / OPENAI_API_KEY / GOOGLE_API_KEY in backend/.env "
        + "to switch on a real model.)"
    )


def _classify_intent(text: str) -> str:
    t = text.lower()
    if any(k in t for k in ("code", "bug", "stack trace", "function", "class ", "typescript", "python")):
        return "code"
    if any(k in t for k in ("research", "find", "compare", "competitor", "paper", "article")):
        return "research"
    if any(k in t for k in ("design", "ui", "ux", "figma", "layout", "component")):
        return "design"
    if any(k in t for k in ("startup", "market", "business", "investor", "pitch", "revenue")):
        return "business"
    return "general"


def _draft_answer(user_message: str, intent: str) -> str:
    short = _truncate(user_message, 220)
    if intent == "code":
        return (
            f"For the request \"{short}\" the recommended approach is to add a small,"
            " self-contained module with explicit types, an integration test, and a"
            " short docstring describing the contract."
        )
    if intent == "research":
        return (
            f"Top-level findings on \"{short}\": (i) the field is moving fast, expect"
            " breaking changes; (ii) treat any single source as a hypothesis until"
            " corroborated; (iii) prioritise primary sources and recent reviews."
        )
    if intent == "design":
        return (
            f"For \"{short}\", optimise for legibility on first glance: a 12-column"
            " grid, a single accent colour, and progressive disclosure for advanced"
            " controls."
        )
    if intent == "business":
        return (
            f"For \"{short}\", articulate the wedge in one sentence, validate with"
            " 5-7 customer interviews, and price for the smallest viable cohort"
            " before broadening."
        )
    return (
        f"Acknowledged: \"{short}\". Manus Core will execute the plan above and"
        " stream intermediate results into the chat as each sub-task completes."
    )


def _truncate(text: str, limit: int) -> str:
    text = " ".join(text.split())
    return text if len(text) <= limit else text[: limit - 1] + "…"


__all__ = ["MockProvider"]
