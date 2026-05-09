# Manus Core — Architecture

This document describes the architecture of Manus Core, an "AI operating system"
that orchestrates multiple LLM providers and autonomous agents behind a single
intelligent interface.

## 1. Goals

1. **Multi-AI orchestration** — route each task to the best LLM (Claude / GPT /
   Gemini / DeepSeek) and combine their outputs.
2. **Autonomous multi-agent workflows** — plan, delegate, execute, and verify
   tasks across specialised agents (Developer, Researcher, Designer, …).
3. **Long-term memory** — recall previous projects, user preferences, and
   semantic context across sessions.
4. **Tooling** — files, web research, terminal execution, code execution.
5. **Production-ready scaffolding** — type-safe Python + TypeScript, clean
   module boundaries, deploy configs for Fly.io and Vercel.

## 2. High-level architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                          FRONTEND (Next.js)                      │
│   Chat · Agents · Files · Projects · Terminal · Memory · Editor  │
└──────────────────────────────┬───────────────────────────────────┘
                               │ REST + SSE (JSON)
┌──────────────────────────────▼───────────────────────────────────┐
│                            BACKEND (FastAPI)                     │
│                                                                  │
│   ┌────────────────────────────────────────────────────────┐    │
│   │                Manus Core Orchestrator                 │    │
│   │  parse → plan (TaskPlanner) → route → execute →        │    │
│   │  reflect (ReasoningEngine) → respond                   │    │
│   └────────┬─────────────┬─────────────┬─────────┬─────────┘    │
│            │             │             │         │              │
│   ┌────────▼─────┐ ┌─────▼──────┐ ┌────▼─────┐ ┌─▼───────────┐  │
│   │  AI Router   │ │AgentManager│ │ToolMgr   │ │ContextEngine│  │
│   │  providers/  │ │ agents/    │ │tools/    │ │ memory/     │  │
│   └──────────────┘ └────────────┘ └──────────┘ └─────────────┘  │
│                                                                  │
│   ┌────────────────────────────────────────────────────────┐    │
│   │              Memory (ChromaDB + RAG)                   │    │
│   │  conversations · projects · files · user profile       │    │
│   └────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

## 3. Module breakdown

### 3.1 Orchestrator (`backend/app/core/orchestrator.py`)
Entry point for every user request. Pipeline:
1. **Parse** — normalise the request, attach session context.
2. **Plan** — `TaskPlanner` decomposes the request into typed steps.
3. **Route** — for each step decide whether it goes to an LLM (via `AIRouter`),
   to an agent (via `AgentManager`), or to a tool (via `ToolManager`).
4. **Execute** — run steps sequentially or in parallel.
5. **Reflect** — `ReasoningEngine` runs self-check / confidence estimation and
   may loop back to step 2.
6. **Respond** — stream tokens to the frontend (SSE) and persist into memory.

### 3.2 AI Router (`backend/app/core/ai_router.py`)
Pluggable provider system. Each provider implements `BaseProvider.complete()`
and `BaseProvider.embed()`. Routing rules:

| Task kind        | Preferred provider          | Fallback chain      |
|------------------|----------------------------|---------------------|
| `reasoning`      | Claude                      | OpenAI → Gemini → Mock |
| `coding`         | DeepSeek (or Claude)        | OpenAI → Mock       |
| `research`       | Gemini                      | OpenAI → Claude → Mock |
| `creative`       | OpenAI                      | Claude → Mock       |
| `embedding`      | OpenAI `text-embedding-3-*` | Mock embedder       |

If no key for the preferred provider is set, the router transparently falls
back to the next one. The `MockProvider` is always available and produces
deterministic outputs so tests and demos work offline.

### 3.3 Agent Manager (`backend/app/agents/manager.py`)
Manages a registry of typed agents. Each agent extends `BaseAgent` and exposes:

- `role: str`
- `system_prompt: str`
- `async run(task: AgentTask) -> AgentResult`

Built-in agents:

| Agent              | Responsibility                                |
|--------------------|-----------------------------------------------|
| `DeveloperAgent`   | Multi-file coding, architecture proposals     |
| `ResearcherAgent`  | Web research, source verification             |
| `DesignerAgent`    | UI/UX, design briefs, component sketches      |
| `DebuggerAgent`    | Bug triage, log analysis, fix suggestions     |
| `ProductManagerAgent` | Roadmaps, requirements, user stories       |
| `QAAgent`          | Test plans, edge cases, regression checklists |
| `PresentationAgent`| Pitch decks, slide content, narrative flow    |
| `BusinessAnalystAgent` | Market sizing, competitor analysis        |

Agents communicate via the orchestrator's message bus (in-process for the MVP,
swappable to Redis or NATS). They can call tools and read/write memory.

### 3.4 Tool Manager (`backend/app/tools/manager.py`)
Exposes a registry of typed tools the orchestrator and agents can invoke.
MVP tools:

- `web_search` — Tavily / Serper / mock.
- `terminal` — sandboxed shell execution (whitelist of binaries).
- `code_exec` — Python REPL in a subprocess with timeouts.
- `file_read` / `file_write` — workspace-scoped file ops.
- `parse_file` — dispatch to the file-processing system.

### 3.5 Memory (`backend/app/memory/`)
- **`store.py`** — ChromaDB wrapper. Collections: `conversations`, `projects`,
  `files`, `user_profile`, `agent_runs`.
- **`rag.py`** — embed → store → retrieve top-k → optional rerank.
- **`profile.py`** — user / project preferences stored as structured JSON +
  embedded summaries for semantic recall.

The MVP uses an in-process Chroma client with an on-disk persistence directory
(`backend/data/chroma/`). For production, point Chroma at a managed deployment
or swap for Pinecone via the same interface.

### 3.6 File processing (`backend/app/files/parser.py`)
Single dispatch table keyed on file extension:

| Extension       | Parser                          |
|-----------------|---------------------------------|
| `.pdf`          | `pypdf` text extraction         |
| `.docx`         | `python-docx`                   |
| `.xlsx` / `.csv`| `openpyxl` / `csv`              |
| `.txt` / `.md`  | raw text                        |
| `.json`         | structured load + summary       |
| `.zip`          | recursive parse with depth cap  |
| code files      | language-aware chunking         |

Output is always a normalised `ParsedDocument` with `chunks`, `metadata`, and
`summary`.

### 3.7 Reasoning engine (`backend/app/core/reasoning.py`)
- Chain-of-thought prompt templates per task type.
- Tree-of-thought scaffolding (`expand → score → prune`).
- Self-check pass that critiques the candidate response.
- Confidence estimation as a 0–1 score returned alongside the answer.

The engine is deliberately small in the MVP — the goal is to expose the
extension points, not to ship a research-grade reasoner.

### 3.8 Frontend (`frontend/`)
- Next.js 14 app router.
- Tailwind + Framer Motion + lucide-react.
- Components: `Sidebar`, `ChatPanel`, `AgentsPanel`, `FilesPanel`,
  `ProjectsPanel`, `TerminalPanel`, `CodeEditor`, `MemoryViewer`,
  `ThemeToggle`.
- API client (`lib/api.ts`) wraps the backend REST + SSE endpoints.

## 4. Data model

```
User ──< Project ──< Conversation ──< Message
                  └─< File
                  └─< AgentRun ──< AgentStep
```

All entities are persisted both as structured rows (SQLite for the MVP, swap
for Postgres in production) and as embedded summaries in Chroma.

## 5. Sequence: "Build me a startup pitch deck"

```
User → POST /api/chat
   ↓
Orchestrator.plan
   ↓                     (TaskPlanner)
   • step 1: research market (ResearcherAgent + web_search)
   • step 2: draft narrative (BusinessAnalystAgent)
   • step 3: produce slides (PresentationAgent)
   • step 4: critique & polish (QAAgent)
   ↓
Orchestrator.execute  (parallel where possible)
   ↓
ReasoningEngine.reflect  (confidence ≥ 0.7?)
   ↓
Memory.persist  (conversation, project, agent runs)
   ↓
SSE stream → Frontend ChatPanel
```

## 6. Extension points

- **New provider** — implement `BaseProvider`, register in
  `providers/__init__.py`. Routing rules in `ai_router.py` will pick it up.
- **New agent** — extend `BaseAgent`, register in `agents/manager.py`. The UI
  agents panel is data-driven and will show it automatically.
- **New tool** — extend `BaseTool`, register in `tools/manager.py`. Becomes
  available to all agents and the orchestrator.
- **New file type** — add a parser to `files/parser.py` dispatch table.
- **New memory backend** — implement the `MemoryStore` protocol; everything
  else stays the same.

## 7. Non-goals (for the MVP)

- Multi-tenant auth / billing.
- Production-grade sandboxing for terminal/code execution (the MVP whitelists
  a small set of binaries and runs in subprocesses with timeouts).
- True RLHF / fine-tuning loops.
- Native voice in/out (ElevenLabs is wired as a tool but not embedded in the
  chat UI yet).

## 8. Deployment

- **Backend** — Fly.io. `fly deploy` from `backend/`. Uses an attached volume
  for `data/chroma/` and `data/uploads/`.
- **Frontend** — Vercel. `vercel --prod` from `frontend/`. Reads
  `NEXT_PUBLIC_API_URL` from project env.
- **Local** — `docker compose up --build` from the repo root.

## 9. Roadmap

See [`ROADMAP.md`](./ROADMAP.md) for the prioritised list of follow-up work.
