"""Test fixtures — point the backend at a temporary data dir."""

from __future__ import annotations

import os
import tempfile
from collections.abc import Iterator

import pytest


@pytest.fixture(autouse=True, scope="session")
def _isolate_data_dir() -> Iterator[None]:
    tmp = tempfile.mkdtemp(prefix="manus-core-tests-")
    os.environ["DATA_DIR"] = tmp
    # Ensure no stale settings cache from prior imports.
    from app import config

    config.get_settings.cache_clear()
    yield
