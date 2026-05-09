---
name: testing-manus-core
description: How to boot Manus Core locally with the deterministic mock provider and run the primary end-to-end flow (chat orchestration, agents, file→RAG ingest, memory recall, tools). Use this whenever a PR touches the FastAPI backend or the Next.js frontend in this repo.
---

# Testing Manus Core (MVP)

Manus Core ships with a deterministic `MockProvider` that responds without any API keys, so the whole pipeline (orchestrator → agents → memory → tools) can be exercised offline. Real provider keys (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, `DEEPSEEK_API_KEY`, `TAVILY_API_KEY`) are optional — when set, the AI Router prefers them per `TaskKind`.

## Boot the stack locally

Use Python 3.11.x. The repo isn't tested on 3.12.

```bash
# Backend (FastAPI on :8000)
cd backend
/home/ubuntu/.pyenv/versions/3.11.11/bin/python3.11 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
uvicorn app.main:app --host 127.0.0.1 --port 8000

# Frontend (Next.js on :3000)
cd frontend
npm ci
NEXT_PUBLIC_API_URL=http://127.0.0.1:8000 npm run dev -- -p 3000 -H 127.0.0.1
```

Verify both are up:

```bash
curl -sS http://127.0.0.1:8000/health           # {"status":"ok","version":"0.1.0"}
curl -sS http://127.0.0.1:8000/api/status       # mock.available=true, others false unless keys set
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/   # 200
```

The Next.js dev server proxies `/api/*` to `http://localhost:8000` (`frontend/next.config.js`). Don't overlap `npm run build` and `npm run dev` against the same `.next/` — they will fight each other and hot-reload will start serving 404s for CSS chunks. If that happens: `pkill -f "next dev"; rm -rf frontend/.next; npm run dev` again.

## Quality gates (run on every PR)

```bash
# Backend
cd backend && source .venv/bin/activate
ruff check .
mypy app
pytest -q

# Frontend
cd frontend
npm run lint
npx tsc --noEmit
npm run build
```

All six should pass. Backend has 51 source files / 9 tests; frontend build target is ~174 KB first-load JS.

## Primary end-to-end test flow (UI)

This is the minimal flow that proves the orchestrator pipeline + RAG + agent execution actually run, not just that pages render. Run it through the UI; record with `recording_start` if you're in test mode.

1. **Chat (auto-route)** — sidebar `Chat`, leave dropdown on `auto-route`, send `Plan an MVP for a B2B SaaS analytics startup.`
   - Expect: assistant bubble within ~3 s; header `MANUS CORE · MOCK · CONF <0-100>%`; collapsible `PLAN (≥ 2 STEPS)`; `≥ 1 @AGENT` tag.
2. **Chat (forced agent)** — set the dropdown to `developer`, send a coding question.
   - Expect: response tagged `@DEVELOPER`, reasoning block reads `intent → code`, plan uses the developer playbook.
3. **File upload** — sidebar `Files`, drop or click-upload a small `.txt`.
   - Expect: `LAST UPLOAD` panel shows summary + `chunks: ≥ 1`; workspace list grows by one row.
4. **Memory recall** — sidebar `Memory`, namespace `files`, search a phrase from the file.
   - Expect: ≥ 1 hit containing the phrase, metadata shows `name=<filename>`.
5. **Run an agent ad-hoc** — sidebar `Agents`, pick `researcher`, run `Compare ChromaDB and pgvector for a 50-person team.`
   - Expect: `OUTPUT · CONF <n>%` header, ≥ 200 chars output, mention of `research-playbook`.
6. **Theme persistence** — bottom of sidebar, click `Theme` button, F5 reload.
   - Expect: page comes back in the same theme. (Bug found in the first MVP run: `ThemeProvider.tsx` had a `useEffect` race that overwrote `localStorage`. Fixed by moving the persistence write into `toggle()`.)
7. **Tools registry** — sidebar `Tools`.
   - Expect: 6 cards (`web_search`, `terminal`, `code_exec`, `file_read`, `file_write`, `parse_file`) each with collapsible `SCHEMA`.

## Direct API smoke tests (fastest way to debug)

```bash
# Chat — verify plan/confidence/used_provider/used_agents are populated
curl -sS -X POST http://127.0.0.1:8000/api/chat \
  -H 'content-type: application/json' \
  -d '{"message":"Plan an MVP","use_memory":true}' | python3 -m json.tool

# Upload then check memory propagation
printf 'small teams automate planning\n' > /tmp/t.txt
curl -sS -F file=@/tmp/t.txt http://127.0.0.1:8000/api/files/upload | python3 -m json.tool
curl -sS 'http://127.0.0.1:8000/api/memory/files?limit=5' | python3 -m json.tool

# Tools
curl -sS -X POST http://127.0.0.1:8000/api/tools/call \
  -H 'content-type: application/json' \
  -d '{"tool":"web_search","arguments":{"query":"vector dbs"}}' | python3 -m json.tool
```

## Non-obvious behaviour (don't file these as bugs)

- **Tools panel is read-only**. `frontend/app/components/ToolsPanel.tsx` only renders the registry + schemas; there is no UI form to invoke a tool with arguments. Tools are called by the orchestrator and by the agent runner. If you want to assert a specific tool's behaviour, hit `POST /api/tools/call` directly.
- **`terminal` tool runs without a shell**. `backend/app/tools/terminal.py` uses `asyncio.create_subprocess_exec`, so `&&`, `|`, `>`, env-var expansion etc. are passed as literal arguments. Each call invokes a single binary from a small allow-list with a 10 s timeout. This is intentional — no shell injection.
- **Real-provider toggling is automatic**. Drop any of `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GOOGLE_API_KEY` / `DEEPSEEK_API_KEY` / `TAVILY_API_KEY` into `backend/.env`; the `AIRouter` (`backend/app/core/ai_router.py`) re-routes per `TaskKind` automatically. With no keys, mock is used and `confidence` always falls in `[0.55, 0.78]`.
- **CI**: this repo currently has 0 checks. `.github/workflows/ci.yml` was rejected at first push because the OAuth token used by Devin's git proxy lacks the `workflow` scope. The yaml is in the original PR description for the user to add via the GitHub UI. Don't chase CI as a regression until that file lands.
- **Default branch is `bootstrap`**, not `main`. The user is expected to rename it after merging the first PR. Branch naming convention for new work: `devin/<unix-timestamp>-<slug>`.
- **Python 3.12 is not supported**. `pyenv` defaults to 3.12 on the standard Devin VM but the venv must be made with 3.11 (use `/home/ubuntu/.pyenv/versions/3.11.11/bin/python3.11`).

## When something looks broken

- Empty plan / no agents in chat response → `MockProvider` not loaded; check `backend/app/providers/__init__.py` registers it last as the always-available fallback.
- File uploads but no memory hits → look at `backend/app/api/files.py` — the upload handler must call `memory.add(namespace="files", ...)`. The integration test `tests/test_files.py` covers this.
- Frontend serves unstyled HTML → kill `next dev`, delete `frontend/.next`, restart. Usually caused by overlapping a `next build` against a running `next dev`.
- 502 or proxy errors when hitting `/api/*` from the frontend → check `frontend/next.config.js`. Default proxy target is `http://localhost:8000`; override via `NEXT_PUBLIC_API_URL` for non-local backends.
