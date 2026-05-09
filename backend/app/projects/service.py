"""Project workspaces — JSON-backed for the MVP."""

from __future__ import annotations

import json
from pathlib import Path
from threading import Lock
from typing import Any

from ..schemas import Project, ProjectCreate


class ProjectService:
    """Tiny JSON-backed project store.

    Swap with a real database in Phase 2 (see ROADMAP). The interface stays
    the same: list / get / create / append-context.
    """

    def __init__(self, data_dir: Path) -> None:
        self.path = data_dir / "projects.json"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = Lock()
        if not self.path.exists():
            self.path.write_text(json.dumps({"projects": []}))

    def _read(self) -> list[dict[str, Any]]:
        with self._lock:
            try:
                return json.loads(self.path.read_text()).get("projects", [])
            except json.JSONDecodeError:
                return []

    def _write(self, projects: list[dict[str, Any]]) -> None:
        with self._lock:
            self.path.write_text(json.dumps({"projects": projects}, indent=2, default=str))

    def list(self) -> list[Project]:
        return [Project(**p) for p in self._read()]

    def get(self, project_id: str) -> Project | None:
        for p in self._read():
            if p.get("id") == project_id:
                return Project(**p)
        return None

    def create(self, payload: ProjectCreate) -> Project:
        project = Project(name=payload.name, description=payload.description, tags=list(payload.tags))
        projects = self._read()
        projects.append(json.loads(project.model_dump_json()))
        self._write(projects)
        return project
