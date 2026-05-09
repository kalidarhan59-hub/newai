"""AI Router — selects the best available provider for a task kind."""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from ..providers import BaseProvider, ProviderMessage, ProviderResponse


class TaskKind(StrEnum):
    REASONING = "reasoning"
    CODING = "coding"
    RESEARCH = "research"
    CREATIVE = "creative"
    EMBEDDING = "embedding"
    GENERAL = "general"


# Preferred order per task kind. The router walks the list and picks the first
# provider that reports ``available = True``. The mock provider is always at
# the tail so the system never fails for lack of credentials.
_ROUTING: dict[TaskKind, list[str]] = {
    TaskKind.REASONING: ["claude", "openai", "gemini", "mock"],
    TaskKind.CODING: ["deepseek", "claude", "openai", "mock"],
    TaskKind.RESEARCH: ["gemini", "openai", "claude", "mock"],
    TaskKind.CREATIVE: ["openai", "claude", "gemini", "mock"],
    TaskKind.GENERAL: ["claude", "openai", "gemini", "mock"],
    TaskKind.EMBEDDING: ["openai", "mock"],
}


@dataclass
class RouterDecision:
    provider_name: str
    fallback_chain: list[str]


class AIRouter:
    """Routes completion / embedding requests to the best available provider."""

    def __init__(self, providers: dict[str, BaseProvider]) -> None:
        self.providers = providers

    def decide(self, kind: TaskKind) -> RouterDecision:
        chain = _ROUTING.get(kind, _ROUTING[TaskKind.GENERAL])
        for name in chain:
            provider = self.providers.get(name)
            if provider is not None and provider.available:
                return RouterDecision(provider_name=name, fallback_chain=chain)
        # Should never happen because the mock is always available, but be
        # defensive in case someone removes it from the registry.
        return RouterDecision(provider_name="mock", fallback_chain=["mock"])

    async def complete(
        self,
        messages: list[ProviderMessage],
        *,
        kind: TaskKind = TaskKind.GENERAL,
        temperature: float = 0.3,
        max_tokens: int = 1024,
    ) -> ProviderResponse:
        decision = self.decide(kind)
        last_error: Exception | None = None
        chain = [
            decision.provider_name,
            *[n for n in decision.fallback_chain if n != decision.provider_name],
        ]
        for name in chain:
            provider = self.providers.get(name)
            if provider is None or not provider.available:
                continue
            try:
                return await provider.complete(
                    messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                )
            except Exception as e:  # pragma: no cover - network
                last_error = e
                continue
        if last_error is not None:
            raise last_error
        raise RuntimeError("No AI provider available, including the mock.")

    async def embed(self, texts: list[str]) -> list[list[float]]:
        decision = self.decide(TaskKind.EMBEDDING)
        provider = self.providers.get(decision.provider_name)
        assert provider is not None
        return await provider.embed(texts)

    def status(self) -> dict[str, dict[str, object]]:
        return {
            name: {
                "available": p.available,
                "default_model": p.default_model,
            }
            for name, p in self.providers.items()
        }
