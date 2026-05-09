"""End-to-end test of the chat orchestrator (mock provider only)."""

from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import create_app


def test_chat_runs_full_pipeline() -> None:
    with TestClient(create_app()) as client:
        resp = client.post(
            "/api/chat",
            json={"message": "Plan an MVP for a B2B SaaS startup"},
        )
    assert resp.status_code == 200
    body = resp.json()
    assert body["used_provider"] == "mock"
    assert body["session_id"]
    assert body["message"]["role"] == "assistant"
    assert body["message"]["content"]
    assert body["plan"], "Orchestrator should produce a plan"
    assert 0.0 <= body["confidence"] <= 1.0
