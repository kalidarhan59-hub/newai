"use client";

import { useState } from "react";
import { AgentsPanel } from "./components/AgentsPanel";
import { ChatPanel } from "./components/ChatPanel";
import { FilesPanel } from "./components/FilesPanel";
import { MemoryViewer } from "./components/MemoryViewer";
import { ProjectsPanel } from "./components/ProjectsPanel";
import { Sidebar, type Panel } from "./components/Sidebar";
import { StatusBar } from "./components/StatusBar";
import { TerminalPanel } from "./components/TerminalPanel";
import { ToolsPanel } from "./components/ToolsPanel";

export default function Home() {
  const [panel, setPanel] = useState<Panel>("chat");

  return (
    <div className="h-screen flex flex-col bg-bg">
      <div className="flex-1 flex min-h-0">
        <Sidebar active={panel} onChange={setPanel} />
        <main className="flex-1 min-w-0 grid-bg">
          {panel === "chat" && <ChatPanel />}
          {panel === "agents" && <AgentsPanel />}
          {panel === "files" && <FilesPanel />}
          {panel === "projects" && <ProjectsPanel />}
          {panel === "memory" && <MemoryViewer />}
          {panel === "tools" && <ToolsPanel />}
          {panel === "terminal" && <TerminalPanel />}
        </main>
      </div>
      <StatusBar />
    </div>
  );
}
