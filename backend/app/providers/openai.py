"""OpenAI provider (Chat Completions API, no SDK dependency)."""

from __future__ import annotations

import os
from typing import Any

import httpx

from .base import BaseProvider, ProviderMessage, ProviderResponse, _hash_embedding


class OpenAIProvider(BaseProvider):
    name = "openai"
    default_model = "gpt-4o-mini"
    chat_url = "https://api.openai.com/v1/chat/completions"
    embeddings_url = "https://api.openai.com/v1/embeddings"
    embedding_model = "text-embedding-3-small"

    def __init__(self) -> None:
        super().__init__()
        self.api_key = os.environ.get("OPENAI_API_KEY") or None
        self.available = bool(self.api_key)

    async def complete(
        self,
        messages: list[ProviderMessage],
        *,
        model: str | None = None,
        temperature: float = 0.3,
        max_tokens: int = 1024,
    ) -> ProviderResponse:
        if not self.available or not self.api_key:
            raise RuntimeError("OpenAIProvider is not configured (OPENAI_API_KEY missing).")

        payload: dict[str, Any] = {
            "model": model or self.default_model,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        headers = {
            "authorization": f"Bearer {self.api_key}",
            "content-type": "application/json",
        }
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(self.chat_url, json=payload, headers=headers)
            resp.raise_for_status()
            data = resp.json()

        choice = (data.get("choices") or [{}])[0]
        message = choice.get("message", {})
        return ProviderResponse(
            text=message.get("content", ""),
            provider=self.name,
            model=data.get("model", payload["model"]),
            usage=data.get("usage", {}),
            raw=data,
        )

    async def embed(self, texts: list[str]) -> list[list[float]]:
        if not self.available or not self.api_key:
            return [_hash_embedding(t) for t in texts]

        payload = {"model": self.embedding_model, "input": texts}
        headers = {
            "authorization": f"Bearer {self.api_key}",
            "content-type": "application/json",
        }
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(self.embeddings_url, json=payload, headers=headers)
            resp.raise_for_status()
            data = resp.json()
        return [item["embedding"] for item in data.get("data", [])]
