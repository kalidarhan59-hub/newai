"""Projects API."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from ..projects import ProjectService
from ..schemas import Project, ProjectCreate
from .deps import get_projects

router = APIRouter(prefix="/api/projects", tags=["projects"])


@router.get("", response_model=list[Project])
async def list_projects(svc: ProjectService = Depends(get_projects)) -> list[Project]:
    return svc.list()


@router.post("", response_model=Project)
async def create_project(
    payload: ProjectCreate,
    svc: ProjectService = Depends(get_projects),
) -> Project:
    return svc.create(payload)


@router.get("/{project_id}", response_model=Project)
async def get_project(project_id: str, svc: ProjectService = Depends(get_projects)) -> Project:
    project = svc.get(project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="not found")
    return project
