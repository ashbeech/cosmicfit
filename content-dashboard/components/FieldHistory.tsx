'use client';

import { useState } from 'react';
import WordDiff from './WordDiff';
import type { HistoryEntry } from '@/lib/content/data';

/**
 * Per-box version history (the primary, requested version UI). Expands to show
 * this field's prior versions from dash_edit_log — each with an inline word-diff
 * (old→new), the author, and a timestamp — plus a "Restore" button per entry and
 * a restore-to-baseline. Restore is a forward write handled by the parent.
 */
export default function FieldHistory({
  fieldId,
  baselineValue,
  refreshKey,
  onRestore,
}: {
  fieldId: string;
  baselineValue: string;
  /** bump to force a re-fetch after a save. */
  refreshKey: number;
  onRestore: (targetValue: string, label: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const [entries, setEntries] = useState<HistoryEntry[] | null>(null);
  const [loadedKey, setLoadedKey] = useState<number>(-1);
  const [loading, setLoading] = useState(false);

  async function load() {
    setLoading(true);
    try {
      const res = await fetch(`/api/content/field/history?fieldId=${encodeURIComponent(fieldId)}`);
      const data = await res.json();
      setEntries(data.history ?? []);
      setLoadedKey(refreshKey);
    } catch {
      setEntries([]);
    } finally {
      setLoading(false);
    }
  }

  function onToggle(e: React.SyntheticEvent<HTMLDetailsElement>) {
    const isOpen = e.currentTarget.open;
    setOpen(isOpen);
    if (isOpen && (entries === null || loadedKey !== refreshKey)) load();
  }

  return (
    <details className="history" open={open} onToggle={onToggle}>
      <summary>History{entries ? ` (${entries.length})` : ''}</summary>
      {loading && <p className="search-hint">Loading…</p>}
      {entries && entries.length === 0 && !loading && (
        <p className="search-hint">No edits yet — this field is still at its original text.</p>
      )}
      {entries?.map((h) => (
        <div className="history-entry" key={h.id}>
          <div className="meta">
            <span>
              v{h.version} · {h.editedBy}
            </span>
            <span>{new Date(h.editedAt).toLocaleString()}</span>
          </div>
          <WordDiff oldText={h.oldValue ?? ''} newText={h.newValue} />
          <div className="field-footer" style={{ marginTop: 8 }}>
            <span className="section-meta">restore writes a new version — nothing is lost</span>
            <button
              type="button"
              className="btn btn-ghost"
              onClick={() => onRestore(h.newValue, `v${h.version} by ${h.editedBy}`)}
            >
              Restore this version
            </button>
          </div>
        </div>
      ))}
      {entries && (
        <div className="field-footer" style={{ marginTop: 10 }}>
          <span className="section-meta">the original seeded text</span>
          <button
            type="button"
            className="btn btn-ghost"
            onClick={() => onRestore(baselineValue, 'original (baseline)')}
          >
            Restore original
          </button>
        </div>
      )}
    </details>
  );
}
