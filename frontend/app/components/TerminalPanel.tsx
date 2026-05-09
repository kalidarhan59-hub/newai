"use client";

import { Play, Terminal as TerminalIcon } from "lucide-react";
import { useState } from "react";
import { api } from "../../lib/api";

interface Entry {
  command: string;
  stdout: string;
  stderr: string;
  exitCode: number;
}

export function TerminalPanel() {
  const [command, setCommand] = useState("echo привет от manus core");
  const [history, setHistory] = useState<Entry[]>([]);
  const [busy, setBusy] = useState(false);

  async function run() {
    if (!command.trim() || busy) return;
    setBusy(true);
    try {
      const res = await api.callTool("terminal", { command });
      const out = res.output as { stdout: string; stderr: string; exit_code: number };
      setHistory((h) => [
        ...h,
        {
          command,
          stdout: out?.stdout ?? "",
          stderr: out?.stderr ?? "",
          exitCode: out?.exit_code ?? -1,
        },
      ]);
    } catch (e) {
      setHistory((h) => [
        ...h,
        {
          command,
          stdout: "",
          stderr: e instanceof Error ? e.message : String(e),
          exitCode: -1,
        },
      ]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col h-full">
      <div className="border-b border-border px-6 py-4 flex items-center gap-2">
        <TerminalIcon size={16} className="text-accent" />
        <h2 className="text-base font-semibold">Сандбокс-терминал</h2>
        <span className="text-xs text-fg-subtle">
          разрешено: echo, ls, cat, wc, head, tail, grep, find, pwd, date, uname,
          whoami, python3, node
        </span>
      </div>
      <div className="flex-1 overflow-y-auto px-6 py-4 font-mono text-xs space-y-3">
        {history.map((h, i) => (
          <div key={i} className="space-y-1">
            <div className="text-fg-subtle">$ {h.command}</div>
            {h.stdout && <pre className="whitespace-pre-wrap text-fg">{h.stdout}</pre>}
            {h.stderr && <pre className="whitespace-pre-wrap text-red-400">{h.stderr}</pre>}
            <div className="text-fg-subtle">код выхода: {h.exitCode}</div>
          </div>
        ))}
        {history.length === 0 && (
          <div className="text-fg-subtle">
            Введите команду выше — вывод появится здесь.
          </div>
        )}
      </div>
      <div className="border-t border-border p-4 flex gap-2">
        <input
          value={command}
          onChange={(e) => setCommand(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && run()}
          className="flex-1 bg-bg-elevated border border-border rounded-lg px-3 py-2 text-sm font-mono"
          placeholder="$"
        />
        <button
          onClick={run}
          disabled={busy}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-accent text-white text-sm disabled:opacity-50 hover:opacity-90"
        >
          <Play size={14} /> запустить
        </button>
      </div>
    </div>
  );
}
