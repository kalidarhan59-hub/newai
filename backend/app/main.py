"""FastAPI entrypoint for the Manus Core backend."""

from __future__ import annotations

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import (
    agents_router,
    chat_router,
    files_router,
    memory_router,
    projects_router,
    tools_router,
    web_router,
)
from .api.deps import get_router_dep
from .config import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    logging.basicConfig(
        level=getattr(logging, settings.log_level.upper(), logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s :: %(message)s",
    )

    app = FastAPI(
        title="Manus Core",
        version="0.1.0",
        description="Мульти-агентная AI-платформа оркестрации.",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(chat_router)
    app.include_router(agents_router)
    app.include_router(files_router)
    app.include_router(memory_router)
    app.include_router(projects_router)
    app.include_router(tools_router)
    app.include_router(web_router)

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok", "version": app.version}

    @app.get("/api/status")
    async def status() -> dict:
        router = get_router_dep()
        return {
            "version": app.version,
            "providers": router.status(),
        }

    @app.get("/")
    async def root() -> dict:
        return {
            "name": "Manus Core",
            "version": app.version,
            "docs": "/docs",
        }

    return app


app = create_app()
