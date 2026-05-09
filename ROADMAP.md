# Manus Core — Roadmap

This roadmap lists the work that turns the MVP scaffold into a production
platform. Each item is scoped so it can be picked up independently.

## Phase 1 — MVP (this PR)

- [x] Monorepo skeleton (FastAPI + Next.js + docker-compose).
- [x] Manus Core Orchestrator with plan / route / execute / reflect pipeline.
- [x] AI Router with Claude, OpenAI, Gemini, DeepSeek, and Mock providers.
- [x] Agent Manager + 8 built-in agents.
- [x] Memory: ChromaDB store + RAG pipeline + user/project profiles.
- [x] Tool Manager: web search, terminal, code exec, file tools.
- [x] File parsing: PDF, DOCX, XLSX, CSV, JSON, TXT, ZIP, code.
- [x] Reasoning engine (CoT + ToT + self-check scaffolding).
- [x] Frontend UI: chat, agents, files, projects, terminal, code editor,
      memory viewer, dark/light theme.
- [x] Deploy configs: Dockerfile, fly.toml, vercel.json.
- [x] CI: lint (ruff + eslint), typecheck (mypy + tsc), unit tests.

## Phase 2 — Hardening

- [ ] Replace SQLite with Postgres + Alembic migrations.
- [ ] Real auth (Clerk or Auth.js) and per-user data isolation.
- [ ] Streaming SSE everywhere (currently chat-only).
- [ ] Persistent agent runs with replay + step-level inspection in the UI.
- [ ] Sandboxed code execution via Firecracker / E2B / Modal.
- [ ] Background workers (Celery or Arq) for long-running agent workflows.
- [ ] Observability: OpenTelemetry traces, structured logs, Sentry.

## Phase 3 — Capability expansion

- [ ] Real voice: ElevenLabs TTS + Whisper STT in the chat panel.
- [ ] Image generation: Stability / OpenAI images / Midjourney bridge.
- [ ] Native browser tool (Playwright) for autonomous web tasks.
- [ ] CrewAI + AutoGen adapters (drop-in alternative to the built-in agent
      manager).
- [ ] LangChain interop layer for the memory and tool subsystems.
- [ ] Project templates: SaaS MVP, pitch deck, market research, technical RFC.

## Phase 4 — Productisation

- [ ] Marketplace of community agents and tools.
- [ ] Per-project knowledge bases with permissioned sharing.
- [ ] Plugin SDK so external services can register tools/agents.
- [ ] Mobile companion app (React Native) for chat + voice.
- [ ] Self-hosted Helm chart.

## Known limitations of the MVP

- The reasoning engine is intentionally small — it exposes hooks but does not
  ship with a research-grade ToT search.
- Terminal and code execution run in subprocesses with a binary whitelist and
  timeouts. Not safe for untrusted multi-tenant use without extra sandboxing.
- The mock provider is deterministic but obviously not a real model. Plug in
  real keys for any serious workload.
- No auth in the MVP; anyone with network access to the backend can use it.
