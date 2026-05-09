"use client";

import { motion } from "framer-motion";
import { Send, Sparkles } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { api, type AgentInfo, type ChatMessage, type PlanStep } from "../../lib/api";

interface UIMessage extends ChatMessage {
  plan?: PlanStep[];
  confidence?: number;
  provider?: string;
  agents?: string[];
}

export function ChatPanel() {
  const [messages, setMessages] = useState<UIMessage[]>([]);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [agents, setAgents] = useState<AgentInfo[]>([]);
  const [agentHint, setAgentHint] = useState<string>("");
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    api.agents().then(setAgents).catch(() => undefined);
  }, []);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages]);

  async function send() {
    if (!input.trim() || busy) return;
    const text = input.trim();
    setInput("");
    setBusy(true);

    const userMsg: UIMessage = {
      id: crypto.randomUUID(),
      role: "user",
      content: text,
      created_at: new Date().toISOString(),
    };
    setMessages((m) => [...m, userMsg]);

    try {
      const resp = await api.chat({
        message: text,
        session_id: sessionId,
        agent: agentHint || null,
      });
      setSessionId(resp.session_id);
      setMessages((m) => [
        ...m,
        {
          ...resp.message,
          plan: resp.plan,
          confidence: resp.confidence,
          provider: resp.used_provider,
          agents: resp.used_agents,
        },
      ]);
    } catch (e) {
      setMessages((m) => [
        ...m,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          content: `**Ошибка:** ${e instanceof Error ? e.message : String(e)}`,
          created_at: new Date().toISOString(),
        },
      ]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col h-full">
      <div className="border-b border-border px-6 py-4 flex items-center justify-between">
        <div>
          <h2 className="text-base font-semibold flex items-center gap-2">
            <Sparkles size={16} className="text-accent" />
            Чат Manus Core
          </h2>
          <p className="text-xs text-fg-subtle mt-0.5">
            {sessionId ? `сессия ${sessionId.slice(0, 8)}…` : "новая сессия"} ·
            {" "}
            мульти-агенты · долговременная память · mock-провайдер до подключения ключей
          </p>
        </div>
        <select
          value={agentHint}
          onChange={(e) => setAgentHint(e.target.value)}
          className="text-xs bg-bg-elevated border border-border rounded-lg px-2 py-1.5 text-fg-muted"
        >
          <option value="">авто-маршрутизация</option>
          {agents.map((a) => (
            <option key={a.name} value={a.name}>
              {a.name}
            </option>
          ))}
        </select>
      </div>

      <div ref={scrollRef} className="flex-1 overflow-y-auto px-6 py-6 space-y-5">
        {messages.length === 0 && <EmptyState />}
        {messages.map((m) => (
          <Message key={m.id} message={m} />
        ))}
        {busy && (
          <div className="text-xs text-fg-subtle px-1 animate-pulse-slow">
            оркестратор выполняет план…
          </div>
        )}
      </div>

      <div className="border-t border-border p-4">
        <div className="flex gap-2 items-end max-w-4xl mx-auto">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                send();
              }
            }}
            placeholder="Попросите Manus Core построить, исследовать, отладить или спланировать…"
            rows={2}
            className="flex-1 resize-none bg-bg-elevated border border-border rounded-xl px-4 py-3 text-sm placeholder:text-fg-subtle focus:outline-none focus:border-accent/60"
          />
          <button
            onClick={send}
            disabled={busy || !input.trim()}
            className="h-12 w-12 grid place-items-center rounded-xl bg-accent text-white disabled:opacity-50 hover:opacity-90 transition-opacity"
            aria-label="отправить"
          >
            <Send size={18} />
          </button>
        </div>
      </div>
    </div>
  );
}

function EmptyState() {
  const samples = [
    "Спланируй MVP для B2B SaaS-стартапа по аналитике.",
    "Найди баг в этом Python stack trace и предложи патч.",
    "Исследуй топ-3 альтернативы Snowflake для команды в 50 человек.",
    "Спроектируй сайдбар для AI-рабочего пространства, dark mode в первую очередь.",
  ];
  return (
    <div className="max-w-2xl mx-auto text-center py-16">
      <div className="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-accent/10 mb-4">
        <Sparkles size={20} className="text-accent" />
      </div>
      <h3 className="text-lg font-semibold">AI-команда в одном чате</h3>
      <p className="text-sm text-fg-muted mt-2">
        Manus Core планирует, маршрутизирует между моделями, запускает специализированных агентов и хранит долговременную память проектов.
      </p>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-6 text-left">
        {samples.map((s) => (
          <div
            key={s}
            className="border border-border bg-bg-elevated rounded-xl px-4 py-3 text-sm text-fg-muted"
          >
            {s}
          </div>
        ))}
      </div>
    </div>
  );
}

function Message({ message }: { message: UIMessage }) {
  const isUser = message.role === "user";
  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      className={`max-w-3xl mx-auto ${isUser ? "ml-auto" : ""}`}
    >
      <div
        className={`rounded-2xl px-4 py-3 text-sm ${
          isUser
            ? "bg-accent/15 border border-accent/30"
            : "bg-bg-elevated border border-border"
        }`}
      >
        <div className="text-[11px] uppercase tracking-wider text-fg-subtle mb-1 flex items-center gap-2">
          <span>{isUser ? "Вы" : "Manus Core"}</span>
          {message.provider && <span className="text-fg-subtle">· {message.provider}</span>}
          {message.confidence != null && (
            <span className="text-fg-subtle">· доверие {(message.confidence * 100).toFixed(0)}%</span>
          )}
        </div>
        <div className="prose-mc">
          <ReactMarkdown remarkPlugins={[remarkGfm]}>{message.content}</ReactMarkdown>
        </div>
        {message.plan && message.plan.length > 0 && (
          <details className="mt-3 group">
            <summary className="text-[11px] uppercase tracking-wider text-fg-subtle cursor-pointer hover:text-fg-muted">
              план ({message.plan.length} шагов)
            </summary>
            <ol className="mt-2 space-y-1 text-xs text-fg-muted">
              {message.plan.map((step) => (
                <li key={step.id} className="flex gap-2">
                  <span className="text-fg-subtle w-5">{step.id}.</span>
                  <span>
                    <span className="text-fg">{step.description}</span>
                    {step.agent && <span className="ml-2 text-accent">@{step.agent}</span>}
                    {step.tool && <span className="ml-2 text-fg-subtle">/{step.tool}</span>}
                  </span>
                </li>
              ))}
            </ol>
          </details>
        )}
        {message.agents && message.agents.length > 0 && (
          <div className="mt-2 flex flex-wrap gap-1">
            {message.agents.map((a, i) => (
              <span
                key={`${a}-${i}`}
                className="text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded bg-bg-subtle text-fg-subtle"
              >
                @{a}
              </span>
            ))}
          </div>
        )}
      </div>
    </motion.div>
  );
}
