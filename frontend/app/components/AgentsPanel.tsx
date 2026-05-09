"use client";

import { Bot, Loader2, Play } from "lucide-react";
import { useEffect, useState } from "react";
import { api, type AgentInfo } from "../../lib/api";

export function AgentsPanel() {
  const [agents, setAgents] = useState<AgentInfo[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [task, setTask] = useState("");
  const [output, setOutput] = useState<string>("");
  const [confidence, setConfidence] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.agents().then((list) => {
      setAgents(list);
      if (list.length > 0) setSelected(list[0].name);
    });
  }, []);

  async function run() {
    if (!selected || !task.trim() || busy) return;
    setBusy(true);
    setError(null);
    setOutput("");
    setConfidence(null);
    try {
      const result = await api.runAgent(selected, task);
      setOutput(result.output);
      setConfidence(result.confidence);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-[260px_1fr] h-full">
      <div className="border-r border-border overflow-y-auto">
        <div className="px-4 py-3 border-b border-border text-xs uppercase tracking-wider text-fg-subtle">
          {agents.length} agents
        </div>
        <ul>
          {agents.map((a) => (
            <li key={a.name}>
              <button
                onClick={() => setSelected(a.name)}
                className={`w-full text-left px-4 py-3 border-b border-border hover:bg-bg-subtle transition-colors ${
                  selected === a.name ? "bg-bg-subtle" : ""
                }`}
              >
                <div className="flex items-center gap-2">
                  <Bot size={14} className="text-accent" />
                  <span className="font-medium text-sm">{a.name}</span>
                </div>
                <div className="text-xs text-fg-muted mt-0.5">{a.role}</div>
              </button>
            </li>
          ))}
        </ul>
      </div>
      <div className="overflow-y-auto p-6">
        {selected ? (
          <AgentDetail
            agent={agents.find((a) => a.name === selected)!}
            task={task}
            onTaskChange={setTask}
            output={output}
            confidence={confidence}
            error={error}
            busy={busy}
            onRun={run}
          />
        ) : (
          <div className="text-fg-subtle text-sm">Loading agents…</div>
        )}
      </div>
    </div>
  );
}

function AgentDetail({
  agent,
  task,
  onTaskChange,
  output,
  confidence,
  error,
  busy,
  onRun,
}: {
  agent: AgentInfo;
  task: string;
  onTaskChange: (v: string) => void;
  output: string;
  confidence: number | null;
  error: string | null;
  busy: boolean;
  onRun: () => void;
}) {
  return (
    <div className="max-w-3xl space-y-4">
      <div>
        <h2 className="text-xl font-semibold">{agent.name}</h2>
        <p className="text-sm text-fg-muted">{agent.role}</p>
        <p className="text-sm text-fg-muted mt-2">{agent.description}</p>
        <div className="mt-3 flex flex-wrap gap-1">
          {agent.capabilities.map((c) => (
            <span
              key={c}
              className="text-[10px] uppercase tracking-wider px-2 py-0.5 rounded bg-bg-subtle text-fg-subtle"
            >
              {c}
            </span>
          ))}
        </div>
      </div>
      <div className="border-t border-border pt-4">
        <label className="text-xs uppercase tracking-wider text-fg-subtle">Run task</label>
        <textarea
          value={task}
          onChange={(e) => onTaskChange(e.target.value)}
          rows={4}
          placeholder="Describe what you want this agent to do…"
          className="mt-2 w-full bg-bg-elevated border border-border rounded-xl px-4 py-3 text-sm placeholder:text-fg-subtle focus:outline-none focus:border-accent/60"
        />
        <button
          onClick={onRun}
          disabled={busy || !task.trim()}
          className="mt-3 inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-accent text-white text-sm disabled:opacity-50 hover:opacity-90"
        >
          {busy ? <Loader2 size={14} className="animate-spin" /> : <Play size={14} />}
          run @{agent.name}
        </button>
      </div>
      {error && (
        <div className="border border-red-500/40 bg-red-500/10 text-red-300 rounded-xl px-4 py-3 text-sm">
          {error}
        </div>
      )}
      {output && (
        <div className="border border-border bg-bg-elevated rounded-xl px-4 py-3 text-sm whitespace-pre-wrap">
          <div className="text-[11px] uppercase tracking-wider text-fg-subtle mb-1">
            output{confidence != null && ` · conf ${(confidence * 100).toFixed(0)}%`}
          </div>
          {output}
        </div>
      )}
    </div>
  );
}
