"""Google Gemini provider (REST API, no SDK dependency)."""

from __future__ import annotations

import os
from typing import Any

import httpx

from .base import BaseProvider, ProviderMessage, ProviderResponse


class GeminiProvider(BaseProvider):
    name = "gemini"
    default_model = "gemini-1.5-flash"

    def __init__(self) -> None:
        super().__init__()
        self.api_key = os.environ.get("GOOGLE_API_KEY") or None
        self.available = bool(self.api_key)

    def _url(self, model: str) -> str:
        return (
            f"https://generativelanguage.googleapis.com/v1beta/models/"
            f"{model}:generateContent?key={self.api_key}"
        )

    async def complete(
        self,
        messages: list[ProviderMessage],
        *,
        model: str | None = None,
        temperature: float = 0.3,
        max_tokens: int = 1024,
    ) -> ProviderResponse:
        if not self.available or not self.api_key:
            raise RuntimeError("GeminiProvider is not configured (GOOGLE_API_KEY missing).")

        chosen_model = model or self.default_model
        contents: list[dict[str, Any]] = []
        system_text = "\n\n".join(m.content for m in messages if m.role == "system")
        for m in messages:
            if m.role == "system":
                continue
            contents.append(
                {
                    "role": "user" if m.role == "user" else "model",
                    "parts": [{"text": m.content}],
                }
            )

        payload: dict[str, Any] = {
            "contents": contents or [{"role": "user", "parts": [{"text": ""}]}],
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": max_tokens,
            },
        }
        if system_text:
            payload["systemInstruction"] = {"parts": [{"text": system_text}]}

        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(self._url(chosen_model), json=payload)
            resp.raise_for_status()
            data = resp.json()

        candidates = data.get("candidates") or []
        text = ""
        if candidates:
            parts = candidates[0].get("content", {}).get("parts", [])
            text = "".join(p.get("text", "") for p in parts)

        return ProviderResponse(
            text=text,
            provider=self.name,
            model=chosen_model,
            usage=data.get("usageMetadata", {}),
            raw=data,
        )
