"""Files API — upload, list, parse."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from ..config import Settings, get_settings
from ..files import parse_bytes
from ..memory import RAGPipeline
from ..schemas import FileInfo, ParsedDocument
from .deps import get_rag

router = APIRouter(prefix="/api/files", tags=["files"])


@router.post("/upload", response_model=ParsedDocument)
async def upload(
    file: Annotated[UploadFile, File(...)],
    settings: Settings = Depends(get_settings),
    rag: RAGPipeline = Depends(get_rag),
) -> ParsedDocument:
    name = file.filename or "uploaded"
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="empty file")

    file_id = str(uuid4())
    target = settings.upload_dir / f"{file_id}__{name}"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)

    doc = parse_bytes(data, name)
    doc.file_id = file_id
    doc.metadata.update(
        {"stored_path": str(target), "uploaded_at": datetime.now(UTC).isoformat()}
    )

    if doc.chunks:
        await rag.ingest(
            "files",
            "\n\n".join(doc.chunks),
            metadata={"file_id": file_id, "name": name, "content_type": doc.content_type},
        )
    return doc


@router.get("", response_model=list[FileInfo])
async def list_files(settings: Settings = Depends(get_settings)) -> list[FileInfo]:
    files: list[FileInfo] = []
    for p in sorted(settings.upload_dir.glob("*"), key=lambda x: x.stat().st_mtime, reverse=True):
        if not p.is_file():
            continue
        file_id, _, original = p.name.partition("__")
        files.append(
            FileInfo(
                file_id=file_id,
                name=original or p.name,
                size=p.stat().st_size,
                content_type="application/octet-stream",
                uploaded_at=datetime.fromtimestamp(p.stat().st_mtime, tz=UTC),
            )
        )
    return files
