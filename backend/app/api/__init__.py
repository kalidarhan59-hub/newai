"""FastAPI routers."""

from .agents import router as agents_router
from .chat import router as chat_router
from .files import router as files_router
from .memory import router as memory_router
from .projects import router as projects_router
from .tools import router as tools_router
from .web import router as web_router

__all__ = [
    "agents_router",
    "chat_router",
    "files_router",
    "memory_router",
    "projects_router",
    "tools_router",
    "web_router",
]
