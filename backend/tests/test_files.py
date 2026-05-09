"""File parser tests."""

from __future__ import annotations

import io
import json
import zipfile

from app.files.parser import parse_bytes


def test_parse_text() -> None:
    doc = parse_bytes(b"hello world\nthis is a test", "notes.txt")
    assert doc.chunks
    assert "hello world" in doc.chunks[0]
    assert doc.summary


def test_parse_json() -> None:
    payload = json.dumps({"a": 1, "b": [1, 2, 3]}).encode()
    doc = parse_bytes(payload, "data.json")
    assert doc.metadata["top_level_keys"] == ["a", "b"]


def test_parse_zip_recurses() -> None:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        zf.writestr("a.txt", "hello inner")
        zf.writestr("b.json", json.dumps({"nested": True}))
    doc = parse_bytes(buf.getvalue(), "bundle.zip")
    assert "a.txt" in doc.summary
    assert doc.metadata["entries"] >= 2
