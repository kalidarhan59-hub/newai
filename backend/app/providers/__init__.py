"""AI provider implementations."""

from __future__ import annotations

from .base import BaseProvider, ProviderMessage, ProviderResponse
from .claude import ClaudeProvider
from .deepseek import DeepSeekProvider
from .gemini import GeminiProvider
from .mock import MockProvider
from .openai import OpenAIProvider

__all__ = [
    "BaseProvider",
    "ClaudeProvider",
    "DeepSeekProvider",
    "GeminiProvider",
    "MockProvider",
    "OpenAIProvider",
    "ProviderMessage",
    "ProviderResponse",
    "build_default_providers",
]


def build_default_providers() -> dict[str, BaseProvider]:
    """Instantiate one provider per supported backend.

    Each provider self-detects whether it has credentials. Providers without
    credentials are still constructed but report ``available = False`` and the
    AI router will skip over them.
    """

    return {
        "claude": ClaudeProvider(),
        "openai": OpenAIProvider(),
        "gemini": GeminiProvider(),
        "deepseek": DeepSeekProvider(),
        "mock": MockProvider(),
    }
