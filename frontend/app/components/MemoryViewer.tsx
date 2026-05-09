"use client";

import { Loader2, Search } from "lucide-react";
import { useEffect, useState } from "react";
import { api, type MemoryEntry } from "../../lib/api";

const NAMESPACES: Array<{ id: string; label: string }> = [
  { id: "conversations", label: "разговоры" },
  { id: "files", label: "файлы" },
  { id: "projects", label: "проекты" },
];

export function MemoryViewer() {
  const [namespace, setNamespace] = useState("conversations");
  const [items, setItems] = useState<MemoryEntry[]>([]);
  const [query, setQuery] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setBusy(true);
    api
      .memoryList(namespace, 50)
      .then(setItems)
      .finally(() => setBusy(false));
  }, [namespace]);

  async function search() {
    if (!query.trim()) {
      setBusy(true);
      const list = await api.memoryList(namespace, 50);
      setItems(list);
      setBusy(false);
      return;
    }
    setBusy(true);
    try {
      const list = await api.memorySearch(query, namespace, 20);
      setItems(list);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col h-full">
      <div className="border-b border-border px-6 py-4 flex items-center gap-3">
        <select
          value={namespace}
          onChange={(e) => setNamespace(e.target.value)}
          className="bg-bg-elevated border border-border rounded-lg px-3 py-2 text-sm"
        >
          {NAMESPACES.map((n) => (
            <option key={n.id} value={n.id}>
              {n.label}
            </option>
          ))}
        </select>
        <div className="flex-1 flex items-center gap-2 bg-bg-elevated border border-border rounded-lg px-3">
          <Search size={14} className="text-fg-subtle" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && search()}
            placeholder="Семантический поиск по памяти…"
            className="flex-1 bg-transparent py-2 text-sm focus:outline-none"
          />
        </div>
        <button
          onClick={search}
          className="px-3 py-2 rounded-lg bg-accent text-white text-sm hover:opacity-90"
        >
          найти
        </button>
      </div>
      <div className="flex-1 overflow-y-auto p-6 space-y-2">
        {busy && (
          <div className="flex items-center gap-2 text-fg-subtle text-sm">
            <Loader2 size={14} className="animate-spin" /> загрузка…
          </div>
        )}
        {!busy && items.length === 0 && (
          <p className="text-sm text-fg-subtle">В этом пространстве имён ещё нет записей.</p>
        )}
        {items.map((item) => (
          <div
            key={item.id}
            className="border border-border bg-bg-elevated rounded-xl px-4 py-3 text-sm"
          >
            <div className="text-[11px] uppercase tracking-wider text-fg-subtle flex justify-between">
              <span>{item.id}</span>
              {item.score > 0 && <span>релевантность {item.score.toFixed(2)}</span>}
            </div>
            <div className="mt-1 whitespace-pre-wrap line-clamp-6">{item.text}</div>
            {Object.keys(item.metadata).length > 0 && (
              <div className="mt-2 text-[11px] text-fg-subtle">
                {Object.entries(item.metadata)
                  .filter(([k]) => !["session_id", "chunk_index"].includes(k))
                  .map(([k, v]) => `${k}=${String(v)}`)
                  .join(" · ")}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
