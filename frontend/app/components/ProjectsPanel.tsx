"use client";

import { FolderPlus, Loader2 } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { api, type Project } from "../../lib/api";

export function ProjectsPanel() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [busy, setBusy] = useState(false);

  const refresh = useCallback(() => {
    api.projects().then(setProjects).catch(() => undefined);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  async function create() {
    if (!name.trim() || busy) return;
    setBusy(true);
    try {
      await api.createProject(name.trim(), description.trim());
      setName("");
      setDescription("");
      refresh();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-[1fr_360px] h-full">
      <div className="p-6 overflow-y-auto">
        <div className="text-xs uppercase tracking-wider text-fg-subtle mb-2">
          projects ({projects.length})
        </div>
        {projects.length === 0 && (
          <p className="text-sm text-fg-subtle">No projects yet — create one on the right.</p>
        )}
        <ul className="space-y-2">
          {projects.map((p) => (
            <li
              key={p.id}
              className="border border-border bg-bg-elevated rounded-xl px-4 py-3"
            >
              <div className="font-medium text-sm">{p.name}</div>
              {p.description && (
                <div className="text-xs text-fg-muted mt-1">{p.description}</div>
              )}
              <div className="text-[11px] text-fg-subtle mt-1">
                {new Date(p.created_at).toLocaleString()}
              </div>
            </li>
          ))}
        </ul>
      </div>
      <aside className="border-l border-border p-5 space-y-3">
        <div className="text-xs uppercase tracking-wider text-fg-subtle">
          new project
        </div>
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Project name"
          className="w-full bg-bg-elevated border border-border rounded-lg px-3 py-2 text-sm"
        />
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Description (optional)"
          rows={3}
          className="w-full bg-bg-elevated border border-border rounded-lg px-3 py-2 text-sm"
        />
        <button
          onClick={create}
          disabled={busy || !name.trim()}
          className="w-full inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg bg-accent text-white text-sm disabled:opacity-50 hover:opacity-90"
        >
          {busy ? <Loader2 size={14} className="animate-spin" /> : <FolderPlus size={14} />}
          create
        </button>
      </aside>
    </div>
  );
}
