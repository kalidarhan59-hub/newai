"""Run a short Python snippet in a subprocess with a tight timeout."""

from __future__ import annotations

import asyncio
import sys
from typing import Any

from .base import BaseTool


class CodeExecTool(BaseTool):
    name = "code_exec"
    description = "Выполнить короткий Python-сниппет в изолированном процессе (таймаут 10 с)."
    schema = {
        "type": "object",
        "properties": {
            "code": {"type": "string"},
            "timeout": {"type": "number", "default": 10},
        },
        "required": ["code"],
    }

    async def call(self, arguments: dict[str, Any]) -> dict[str, Any]:
        code = str(arguments.get("code", ""))
        timeout = float(arguments.get("timeout", 10))
        if not code.strip():
            return {"stdout": "", "stderr": "empty code", "exit_code": 1}
        proc = await asyncio.create_subprocess_exec(
            sys.executable,
            "-I",
            "-c",
            code,
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
