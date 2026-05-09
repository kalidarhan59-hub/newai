"use client";

import { Wrench } from "lucide-react";
import { useEffect, useState } from "react";
import { api, type ToolInfo } from "../../lib/api";

export function ToolsPanel() {
  const [tools, setTools] = useState<ToolInfo[]>([]);

  useEffect(() => {
    api.tools().then(setTools).catch(() => undefined);
  }, []);

  return (
    <div className="flex flex-col h-full">
      <div className="border-b border-border px-6 py-4 flex items-center gap-2">
        <Wrench size={16} className="text-accent" />
        <h2 className="text-base font-semibold">Реестр инструментов</h2>
      </div>
      <div className="flex-1 overflow-y-auto p-6">
        <ul className="space-y-2">
          {tools.map((t) => (
            <li
              key={t.name}
              className="border border-border bg-bg-elevated rounded-xl px-4 py-3"
            >
              <div className="font-medium text-sm">{t.name}</div>
              <div className="text-xs text-fg-muted mt-0.5">{t.description}</div>
              <details className="mt-2">
                <summary className="text-[11px] uppercase tracking-wider text-fg-subtle cursor-pointer">
                  схема
                </summary>
                <pre className="mt-2 text-[11px] bg-bg-subtle border border-border rounded-lg p-3 overflow-x-auto">
                  {JSON.stringify(t.schema, null, 2)}
                </pre>
              </details>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
