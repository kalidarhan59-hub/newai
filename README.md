# Manus Core

> Multi-agent AI platform that combines several AI models and specialised agents into a single intelligent workspace.

Manus Core is an opinionated MVP scaffold for building an "AI operating system":
an orchestrator that routes between multiple LLM providers, runs autonomous
multi-agent workflows, keeps long-term semantic memory, and exposes a futuristic
chat / projects / agents / files / terminal UI.

The repository is built to be extended. Out of the box it ships with mock AI
providers so the whole stack runs locally without any API keys, and gracefully
upgrades to real Claude / GPT / Gemini / DeepSeek / ElevenLabs / Tavily once you
plug credentials into `.env`.

---

## Highlights

- **Manus Core Orchestrator** — single entry point that plans, routes, and
  reconciles multi-agent tasks.
- **Multi-agent system** — Developer, Researcher, Designer, Debugger, Product
  Manager, QA, Business Analyst, Presentation agents. Easy to add more.
- **AI Router** — pluggable provider layer with Claude, OpenAI, Gemini,
  DeepSeek, and a deterministic Mock provider for offline development.
- **Long-term memory** — ChromaDB vector store + RAG pipeline + user/project
  profiles + session recall.
- **File understanding** — PDF, DOCX, XLSX, CSV, JSON, TXT, code archives, ZIP.
- **Tool manager** — web search, terminal execution (sandboxed), code
  execution, file tools.
- **Reasoning engine** — chain-of-thought, tree-of-thought, self-check, and
  confidence estimation hooks.
- **Frontend** — Next.js 14 + Tailwind + Framer Motion. Chat, agents panel,
  files, projects, terminal, code editor, memory viewer, dark/light theme.
- **Deploy-ready** — Dockerfile + `fly.toml` for the backend, `vercel.json` for
  the frontend, `docker-compose.yml` for local development.

See [`ARCHITECTURE.md`](./ARCHITECTURE.md) for the full design and
[`ROADMAP.md`](./ROADMAP.md) for the implementation plan.

---

## Quick start

### 1. Local development (no API keys required)

```bash
# Backend
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
uvicorn app.main:app --reload --port 8000

# Frontend (in a second shell)
cd frontend
npm install
npm run dev
```

Then open <http://localhost:3000>. The Mock AI provider responds
deterministically, so the full UX works without any API keys.

### 2. With real AI providers

Copy `backend/.env.example` to `backend/.env` and fill in any subset of:

```
ANTHROPIC_API_KEY=...
OPENAI_API_KEY=...
GOOGLE_API_KEY=...
DEEPSEEK_API_KEY=...
TAVILY_API_KEY=...
ELEVENLABS_API_KEY=...
```

Manus Core will automatically prefer real providers when their key is set and
fall back to the mock provider otherwise. Routing rules live in
[`backend/app/core/ai_router.py`](./backend/app/core/ai_router.py).

### 3. Docker compose

```bash
docker compose up --build
```

Brings up backend (`:8000`), frontend (`:3000`), and ChromaDB (`:8001`).

---

## Architecture (one-pager)

```
                        ┌──────────────────────────────┐
                        │        Frontend (Next.js)    │
                        │  chat · agents · files · …   │
                        └──────────────┬───────────────┘
                                       │ REST / SSE
                        ┌──────────────▼───────────────┐
                        │      Manus Core Orchestrator │
                        │   plan → route → execute →   │
                        │     reflect → respond        │
                        └──┬─────────┬─────────┬───────┘
                           │         │         │
              ┌────────────▼──┐  ┌───▼────┐  ┌─▼───────────┐
              │  AI Router    │  │ Agents │  │ Tool Manager│
              │ Claude / GPT  │  │ Dev/QA │  │ web/term/fs │
              │ Gemini / Mock │  │ PM/RES │  │ files/exec  │
              └──────┬────────┘  └───┬────┘  └─────┬───────┘
                     │               │             │
                     └────────┬──────┴─────────────┘
                              │
                  ┌───────────▼────────────┐
                  │       Memory           │
                  │  ChromaDB · RAG ·      │
                  │  user/project profiles │
                  └────────────────────────┘
```

The full architecture, sequence diagrams, data model, and extension points are
in [`ARCHITECTURE.md`](./ARCHITECTURE.md).

---

## Project layout

```
manus-core/
├── backend/                FastAPI + orchestrator + agents + memory
│   ├── app/
│   │   ├── main.py         FastAPI entrypoint
│   │   ├── api/            REST endpoints
│   │   ├── core/           orchestrator, router, reasoning, planner
│   │   ├── agents/         multi-agent system
│   │   ├── providers/      Claude / OpenAI / Gemini / DeepSeek / Mock
│   │   ├── memory/         ChromaDB + RAG
│   │   ├── tools/          web search, terminal, code exec, files
│   │   ├── files/          PDF / DOCX / XLSX / ZIP parsers
│   │   └── projects/       project workspaces
│   └── tests/
├── frontend/               Next.js 14 app router UI
│   ├── app/                pages + components
│   └── lib/                API client
├── docs/                   architecture, roadmap, ADRs
├── infra/                  docker-compose, deploy configs
└── .github/workflows/      CI (lint, typecheck, test)
```

---

## Status

This is an **MVP scaffold**. It is intentionally complete enough to demo every
capability listed in the brief end-to-end, but most modules are wired up to
sensible defaults rather than production-grade implementations. The README and
[`ROADMAP.md`](./ROADMAP.md) call out exactly what is real vs. stubbed, so the
project can be hardened iteratively.

## License

MIT — see [`LICENSE`](./LICENSE).
