# Manus Core — Backend

FastAPI backend for the Manus Core multi-agent platform.

See the top-level [`README.md`](../README.md) and
[`ARCHITECTURE.md`](../ARCHITECTURE.md) for the full picture.

## Run locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
uvicorn app.main:app --reload --port 8000
```

API documentation is served at `http://localhost:8000/docs`.

## Tests / lint / typecheck

```bash
pytest
ruff check .
mypy app
```

## Configuration

Copy `.env.example` to `.env` and fill in any subset of the API keys. The
backend gracefully falls back to the deterministic `mock` provider when keys
are missing.
