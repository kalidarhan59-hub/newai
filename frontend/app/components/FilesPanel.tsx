"use client";

import { File as FileIcon, Loader2, Upload } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { api, type FileInfo, type ParsedDocument } from "../../lib/api";

export function FilesPanel() {
  const [files, setFiles] = useState<FileInfo[]>([]);
  const [drag, setDrag] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [last, setLast] = useState<ParsedDocument | null>(null);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    api.files().then(setFiles).catch(() => undefined);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  async function handleFiles(list: FileList) {
    setError(null);
    setUploading(true);
    try {
      for (const f of Array.from(list)) {
        const doc = await api.uploadFile(f);
        setLast(doc);
      }
      refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-[1fr_360px] h-full">
      <div
        onDragOver={(e) => {
          e.preventDefault();
          setDrag(true);
        }}
        onDragLeave={() => setDrag(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDrag(false);
          if (e.dataTransfer.files) handleFiles(e.dataTransfer.files);
        }}
        className="p-6 overflow-y-auto"
      >
        <label
          className={`block border-2 border-dashed rounded-2xl p-10 text-center cursor-pointer transition-colors ${
            drag
              ? "border-accent bg-accent/10"
              : "border-border hover:border-accent/60 hover:bg-bg-subtle"
          }`}
        >
          <input
            type="file"
            multiple
            className="hidden"
            onChange={(e) => e.target.files && handleFiles(e.target.files)}
          />
          <div className="flex flex-col items-center gap-2">
            {uploading ? (
              <Loader2 size={28} className="animate-spin text-accent" />
            ) : (
              <Upload size={28} className="text-accent" />
            )}
            <div className="text-sm font-medium">
              Drop files here or click to upload
            </div>
            <div className="text-xs text-fg-subtle">
              PDF · DOCX · XLSX · CSV · JSON · TXT · ZIP · code
            </div>
          </div>
        </label>

        {error && (
          <div className="mt-4 border border-red-500/40 bg-red-500/10 text-red-300 rounded-xl px-4 py-3 text-sm">
            {error}
          </div>
        )}

        <div className="mt-6">
          <div className="text-xs uppercase tracking-wider text-fg-subtle mb-2">
            workspace ({files.length})
          </div>
          <ul className="space-y-1">
            {files.map((f) => (
              <li
                key={f.file_id}
                className="flex items-center gap-3 px-3 py-2 rounded-lg border border-border bg-bg-elevated"
              >
                <FileIcon size={14} className="text-fg-subtle" />
                <div className="flex-1 min-w-0">
                  <div className="text-sm truncate">{f.name}</div>
                  <div className="text-xs text-fg-subtle">
                    {(f.size / 1024).toFixed(1)} KB ·{" "}
                    {new Date(f.uploaded_at).toLocaleString()}
                  </div>
                </div>
              </li>
            ))}
          </ul>
        </div>
      </div>

      <aside className="border-l border-border overflow-y-auto p-5">
        <div className="text-xs uppercase tracking-wider text-fg-subtle mb-2">
          last upload
        </div>
        {last ? (
          <div className="text-sm space-y-3">
            <div className="font-medium">{last.name}</div>
            <div className="text-fg-muted">{last.summary}</div>
            <div className="text-xs text-fg-subtle">
              chunks: {last.chunks.length} · type: {last.content_type}
            </div>
          </div>
        ) : (
          <p className="text-sm text-fg-subtle">
            Upload a file to see Manus Core parse it, summarise it, and add it
            to the project memory.
          </p>
        )}
      </aside>
    </div>
  );
}
