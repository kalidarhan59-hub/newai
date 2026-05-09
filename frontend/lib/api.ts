/**
 * Tiny typed wrapper over the Manus Core REST API.
 *
 * In development the Next.js rewrite in `next.config.js` proxies `/api/*` to
 * the FastAPI backend. In production set `NEXT_PUBLIC_API_URL` so the client
 * talks to the deployed backend directly.
 */

export type Role = "user" | "assistant" | "system" | "tool";

export interface ChatMessage {
  id: string;
  role: Role;
  content: string;
  created_at: string;
  metadata?: Record<string, unknown>;
}

export interface PlanStep {
  id: number;
  description: string;
  kind: string;
  agent: string | null;
  tool: string | null;
  depends_on: number[];
}

export interface ChatResponse {
  session_id: string;
  message: ChatMessage;
  plan: PlanStep[];
  confidence: number;
  used_provider: string;
  used_agents: string[];
}

export interface AgentInfo {
  name: string;
  role: string;
  description: string;
  capabilities: string[];
}

export interface FileInfo {
  file_id: string;
  name: string;
  size: number;
  content_type: string;
  uploaded_at: string;
}

export interface ParsedDocument {
  file_id: string;
  name: string;
  content_type: string;
  summary: string;
  chunks: string[];
  metadata: Record<string, unknown>;
}

export interface Project {
  id: string;
  name: string;
  description: string;
  created_at: string;
  tags: string[];
}

export interface MemoryEntry {
  id: string;
  text: string;
  score: number;
  metadata: Record<string, unknown>;
}

export interface ToolInfo {
  name: string;
  description: string;
  schema: Record<string, unknown>;
}

export interface ProviderStatus {
  available: boolean;
  default_model: string;
}

export interface StatusResponse {
  version: string;
  providers: Record<string, ProviderStatus>;
}

const BASE = "";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: { "content-type": "application/json", ...(init?.headers ?? {}) },
    ...init,
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`${res.status} ${res.statusText} :: ${text || path}`);
  }
  return res.json() as Promise<T>;
}

export const api = {
  status: () => request<StatusResponse>("/api/status"),
  chat: (body: {
    message: string;
    session_id?: string | null;
    project_id?: string | null;
    agent?: string | null;
    use_memory?: boolean;
  }) =>
    request<ChatResponse>("/api/chat", {
      method: "POST",
      body: JSON.stringify({
        message: body.message,
        session_id: body.session_id ?? null,
        project_id: body.project_id ?? null,
        agent: body.agent ?? null,
        use_memory: body.use_memory ?? true,
      }),
    }),
  history: (sessionId: string) =>
    request<{ session_id: string; messages: Array<Record<string, unknown>> }>(
      `/api/chat/${sessionId}/messages`,
    ),
  agents: () => request<AgentInfo[]>("/api/agents"),
  runAgent: (agent: string, task: string, context: Record<string, unknown> = {}) =>
    request<{
      agent: string;
      success: boolean;
      output: string;
      artifacts: unknown[];
      confidence: number;
    }>("/api/agents/run", {
      method: "POST",
      body: JSON.stringify({ agent, task, context }),
    }),
  files: () => request<FileInfo[]>("/api/files"),
  uploadFile: async (file: File): Promise<ParsedDocument> => {
    const fd = new FormData();
    fd.append("file", file);
    const res = await fetch(`${BASE}/api/files/upload`, { method: "POST", body: fd });
    if (!res.ok) throw new Error(`upload failed: ${res.status}`);
    return res.json();
  },
  projects: () => request<Project[]>("/api/projects"),
  createProject: (name: string, description = "", tags: string[] = []) =>
    request<Project>("/api/projects", {
      method: "POST",
      body: JSON.stringify({ name, description, tags }),
    }),
  memorySearch: (query: string, namespace = "conversations", topK = 10) =>
    request<MemoryEntry[]>("/api/memory/search", {
      method: "POST",
      body: JSON.stringify({ query, namespace, top_k: topK }),
    }),
  memoryList: (namespace: string, limit = 50) =>
    request<MemoryEntry[]>(`/api/memory/${namespace}?limit=${limit}`),
  tools: () => request<ToolInfo[]>("/api/tools"),
  callTool: (tool: string, args: Record<string, unknown>) =>
    request<{ tool: string; success: boolean; output: unknown; error: string | null }>(
      "/api/tools/call",
      {
        method: "POST",
        body: JSON.stringify({ tool, arguments: args }),
      },
    ),
  webSearch: (q: string, max = 5) =>
    request<{ tool: string; output: { results: Array<{ title: string; url: string; snippet: string }>; provider?: string } }>(
      `/api/web/search?q=${encodeURIComponent(q)}&max_results=${max}`,
    ),
};
