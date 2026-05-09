"""Anthropic Claude provider (HTTP, no SDK dependency)."""

from __future__ import annotations

import os
from typing import Any

import httpx

from .base import BaseProvider, ProviderMessage, ProviderResponse


class ClaudeProvider(BaseProvider):
    name = "claude"
    default_model = "claude-3-5-sonnet-latest"
    api_base = "https://api.anthropic.com/v1/messages"

    def __init__(self) -> None:
        super().__init__()
        self.api_key = os.environ.get("ANTHROPIC_API_KEY") or None
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
            raise RuntimeError("ClaudeProvider is not configured (ANTHROPIC_API_KEY missing).")

        system_messages = [m.content for m in messages if m.role == "system"]
        chat_messages: list[dict[str, Any]] = [
            {"role": ("user" if m.role == "user" else "assistant"), "content": m.content}
            for m in messages
            if m.role in ("user", "assistant")
        ]

        payload: dict[str, Any] = {
            "model": model or self.default_model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": chat_messages or [{"role": "user", "content": ""}],
        }
        if system_messages:
            payload["system"] = "\n\n".join(system_messages)

        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(self.api_base, json=payload, headers=headers)
            resp.raise_for_status()
            data = resp.json()

        text_chunks = [
            block.get("text", "")
            for block in data.get("content", [])
            if block.get("type") == "text"
        ]
        return ProviderResponse(
            text="".join(text_chunks),
            provider=self.name,
            model=data.get("model", payload["model"]),
            usage=data.get("usage", {}),
            raw=data,
        )
