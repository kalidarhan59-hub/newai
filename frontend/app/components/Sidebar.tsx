"use client";

import {
  Bot,
  Brain,
  FileText,
  FolderKanban,
  MessageSquare,
  Sparkles,
  Terminal,
  Wrench,
} from "lucide-react";
import { useTheme } from "./ThemeProvider";

export type Panel =
  | "chat"
  | "agents"
  | "files"
  | "projects"
  | "memory"
  | "terminal"
  | "tools";

const items: Array<{ id: Panel; label: string; icon: React.ReactNode }> = [
  { id: "chat", label: "Чат", icon: <MessageSquare size={18} /> },
  { id: "agents", label: "Агенты", icon: <Bot size={18} /> },
  { id: "files", label: "Файлы", icon: <FileText size={18} /> },
  { id: "projects", label: "Проекты", icon: <FolderKanban size={18} /> },
  { id: "memory", label: "Память", icon: <Brain size={18} /> },
  { id: "tools", label: "Инструменты", icon: <Wrench size={18} /> },
  { id: "terminal", label: "Терминал", icon: <Terminal size={18} /> },
];

export function Sidebar({
  active,
  onChange,
}: {
  active: Panel;
  onChange: (panel: Panel) => void;
}) {
  const { theme, toggle } = useTheme();
  return (
    <aside className="w-60 shrink-0 border-r border-border bg-bg-elevated flex flex-col">
      <div className="px-4 py-5 border-b border-border flex items-center gap-2">
        <div className="w-8 h-8 rounded-lg bg-accent/15 grid place-items-center">
          <Sparkles size={18} className="text-accent" />
        </div>
        <div>
          <div className="text-sm font-semibold tracking-wide">Manus Core</div>
          <div className="text-[11px] text-fg-subtle">AI-операционная система</div>
        </div>
      </div>
      <nav className="flex-1 p-2 space-y-1">
        {items.map((item) => (
          <button
            key={item.id}
            onClick={() => onChange(item.id)}
            className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition-colors ${
              active === item.id
                ? "bg-accent/15 text-fg shadow-glow"
                : "hover:bg-bg-subtle text-fg-muted hover:text-fg"
            }`}
          >
            {item.icon}
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
      <div className="p-3 border-t border-border">
        <button
          onClick={toggle}
          className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm hover:bg-bg-subtle text-fg-muted hover:text-fg"
        >
          <span>Тема</span>
          <span className="text-xs uppercase tracking-wider">
            {theme === "dark" ? "тёмная" : "светлая"}
          </span>
        </button>
        <a
          href="https://github.com"
          target="_blank"
          rel="noreferrer"
          className="mt-1 block px-3 py-2 text-[11px] text-fg-subtle hover:text-fg-muted"
        >
          v0.1.0 · MIT
        </a>
      </div>
    </aside>
  );
}
