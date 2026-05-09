"""Base interface every AI provider implements."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any


@dataclass
class ProviderMessage:
    role: str
    content: str


@dataclass
class ProviderResponse:
    text: str
    provider: str
    model: str
    usage: dict[str, Any] = field(default_factory=dict)
    raw: dict[str, Any] = field(default_factory=dict)


class BaseProvider(ABC):
    """Abstract LLM provider.

    Concrete providers must override :py:meth:`complete` and may override
    :py:meth:`embed`. Providers without credentials should set
    ``self.available = False`` so the router can skip them.
    """

    name: str = "base"
    default_model: str = ""

    def __init__(self) -> None:
        self.available: bool = False

    @abstractmethod
    async def complete(
        self,
        messages: list[ProviderMessage],
        *,
        model: str | None = None,
        temperature: float = 0.3,
        max_tokens: int = 1024,
    ) -> ProviderResponse:
        """Generate a single completion for ``messages``."""

    async def embed(self, texts: list[str]) -> list[list[float]]:
        """Return embeddings for ``texts``.

        Default implementation produces a deterministic hash-based embedding so
        the rest of the system works without a real embedding model. Override in
        providers that support real embeddings.
        """

        return [_hash_embedding(t) for t in texts]


def _hash_embedding(text: str, dim: int = 256) -> list[float]:
    """Deterministic, low-quality embedding used as a fallback.

    The vector is normalised so cosine similarity is meaningful for tests and
    demos. It is *not* a substitute for a real embedding model.

    blake2b's digest is capped at 64 bytes per call, so for larger ``dim`` we
    chain multiple invocations with a counter suffix.
    """

    import math
    from hashlib import blake2b

    raw_bytes = bytearray()
    counter = 0
    while len(raw_bytes) < dim:
        chunk = blake2b(
            text.encode("utf-8") + counter.to_bytes(4, "big"),
            digest_size=64,
        ).digest()
        raw_bytes.extend(chunk)
        counter += 1
    raw = [(b / 255.0) - 0.5 for b in raw_bytes[:dim]]
    norm = math.sqrt(sum(v * v for v in raw)) or 1.0
    return [v / norm for v in raw]
