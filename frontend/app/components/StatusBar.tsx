"use client";

import { useEffect, useState } from "react";
import { api, type StatusResponse } from "../../lib/api";

export function StatusBar() {
  const [status, setStatus] = useState<StatusResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    const tick = () =>
      api
        .status()
        .then((s) => !cancelled && setStatus(s))
        .catch((e) => !cancelled && setError(e instanceof Error ? e.message : String(e)));
    tick();
    const t = setInterval(tick, 30_000);
    return () => {
      cancelled = true;
      clearInterval(t);
    };
  }, []);

  return (
    <div className="border-t border-border px-4 py-2 flex items-center gap-3 text-[11px] text-fg-subtle bg-bg-elevated">
      <span>v{status?.version ?? "?"}</span>
      <span className="opacity-50">·</span>
      {status ? (
        Object.entries(status.providers).map(([name, info]) => (
          <span key={name} className="flex items-center gap-1">
            <span
              className={`w-2 h-2 rounded-full ${
                info.available ? "bg-emerald-500" : "bg-zinc-600"
              }`}
            />
            {name}
          </span>
        ))
      ) : error ? (
        <span className="text-red-400">бэкенд недоступен: {error}</span>
      ) : (
        <span>подключение…</span>
      )}
    </div>
  );
}
