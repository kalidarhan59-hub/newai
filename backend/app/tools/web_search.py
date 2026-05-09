"""Web search tool — Tavily with a graceful mock fallback."""

from __future__ import annotations

from typing import Any

import httpx

from .base import BaseTool


class WebSearchTool(BaseTool):
    name = "web_search"
    description = "Run a web search and return the top results."
    schema = {
        "type": "object",
        "properties": {
            "query": {"type": "string"},
            "max_results": {"type": "integer", "default": 5},
        },
        "required": ["query"],
    }

    def __init__(self, api_key: str | None) -> None:
        self.api_key = api_key

    async def call(self, arguments: dict[str, Any]) -> dict[str, Any]:
        query = str(arguments.get("query", "")).strip()
        max_results = int(arguments.get("max_results", 5))
        if not query:
            return {"results": [], "provider": "noop"}

        if not self.api_key:
            return {"results": _mock_results(query, max_results), "provider": "mock"}

        async with httpx.AsyncClient(timeout=20.0) as client:
            resp = await client.post(
                "https://api.tavily.com/search",
                json={
                    "api_key": self.api_key,
                    "query": query,
                    "max_results": max_results,
                    "search_depth": "basic",
                    "include_answer": True,
                },
            )
            resp.raise_for_status()
            data = resp.json()
        results = [
            {
                "title": r.get("title", ""),
                "url": r.get("url", ""),
                "snippet": r.get("content", ""),
            }
            for r in data.get("results", [])
        ]
        return {"results": results, "answer": data.get("answer"), "provider": "tavily"}


def _mock_results(query: str, max_results: int) -> list[dict[str, Any]]:
    snippets = [
        f"Overview of '{query}' on a reputable encyclopaedia-style site.",
        f"Recent news article discussing '{query}'.",
        f"Academic paper or technical report related to '{query}'.",
        f"Community discussion summarising '{query}'.",
        f"Vendor documentation page for '{query}'.",
    ]
    return [
        {
            "title": f"Mock result {i + 1}: {query}",
            "url": f"https://example.com/mock/{i + 1}?q={query.replace(' ', '+')}",
            "snippet": snippets[i % len(snippets)],
        }
        for i in range(max_results)
    ]
