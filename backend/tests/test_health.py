"""Smoke tests for the FastAPI app."""

from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import create_app


def _client() -> TestClient:
    return TestClient(create_app())


def test_health_endpoint() -> None:
    with _client() as client:
        resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_status_lists_providers() -> None:
    with _client() as client:
        resp = client.get("/api/status")
    assert resp.status_code == 200
    body = resp.json()
    assert "providers" in body
    assert "mock" in body["providers"]
    assert body["providers"]["mock"]["available"] is True


def test_agents_list() -> None:
    with _client() as client:
        resp = client.get("/api/agents")
    assert resp.status_code == 200
    names = {a["name"] for a in resp.json()}
    assert {"developer", "researcher", "designer", "qa"} <= names
