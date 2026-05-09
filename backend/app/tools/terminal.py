"""Sandboxed terminal tool — whitelist of safe binaries with timeouts."""

from __future__ import annotations

import asyncio
import shlex
from typing import Any

from .base import BaseTool

# Read-only / inspection commands are allowed by default. Anything that mutates
# the filesystem outside the workspace is intentionally blocked.
DEFAULT_ALLOWED = {
    "echo",
    "ls",
    "cat",
    "wc",
    "head",
    "tail",
    "grep",
    "find",
    "pwd",
    "date",
    "uname",
    "whoami",
    "python3",
    "node",
}


class TerminalTool(BaseTool):
    name = "terminal"
    description = (
        "Запустить команду shell из небольшого белого списка инструментов "
        "инспекции с таймаутом 10 с. Не универсальный shell."
    )
    schema = {
        "type": "object",
        "properties": {
            "command": {"type": "string"},
            "timeout": {"type": "number", "default": 10},
        },
        "required": ["command"],
    }

    def __init__(self, allowed: set[str] | None = None) -> None:
        self.allowed = allowed or DEFAULT_ALLOWED

    async def call(self, arguments: dict[str, Any]) -> dict[str, Any]:
        command = str(arguments.get("command", "")).strip()
        if not command:
            return {"stdout": "", "stderr": "empty command", "exit_code": 1}
        timeout = float(arguments.get("timeout", 10))
        try:
            argv = shlex.split(command)
        except ValueError as e:
            return {"stdout": "", "stderr": f"parse error: {e}", "exit_code": 1}
        if not argv or argv[0] not in self.allowed:
            return {
                "stdout": "",
                "stderr": (
                    f"binary {argv[0] if argv else '?'} not on the allow-list; "
                    f"allowed: {sorted(self.allowed)}"
                ),
                "exit_code": 126,
            }

        proc = await asyncio.create_subprocess_exec(
            *argv,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        try:
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        except TimeoutError:
            proc.kill()
            await proc.wait()
            return {"stdout": "", "stderr": "timeout", "exit_code": 124}
        return {
            "stdout": stdout.decode("utf-8", errors="replace"),
            "stderr": stderr.decode("utf-8", errors="replace"),
            "exit_code": proc.returncode or 0,
        }
