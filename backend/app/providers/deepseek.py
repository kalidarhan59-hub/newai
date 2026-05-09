"""DeepSeek provider (OpenAI-compatible Chat Completions API)."""

from __future__ import annotations

import os
from typing import Any

import httpx

from .base import BaseProvider, ProviderMessage, ProviderResponse


class DeepSeekProvider(BaseProvider):
    name = "deepseek"
    default_model = "deepseek-chat"
    chat_url = "https://api.deepseek.com/chat/completions"

    def __init__(self) -> None:
        super().__init__()
        self.api_key = os.environ.get("DEEPSEEK_API_KEY") or None
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
            raise RuntimeError("DeepSeekProvider is not configured (DEEPSEEK_API_KEY missing).")

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
