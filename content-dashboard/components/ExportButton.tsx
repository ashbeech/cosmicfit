'use client';

import { useState } from 'react';

/** POST /api/export → download the reconstructed bundle (.zip). */
export default function ExportButton() {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  async function run() {
    setBusy(true);
    setErr('');
    try {
      const res = await fetch('/api/export', { method: 'POST' });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        setErr(j.error ?? `Export failed (${res.status})`);
        setBusy(false);
        return;
      }
      const blob = await res.blob();
      const cd = res.headers.get('Content-Disposition') ?? '';
      const name = /filename="?([^"]+)"?/.exec(cd)?.[1] ?? 'content-export.zip';
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = name;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch {
      setErr('Export failed.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <button type="button" className="btn btn-primary" onClick={run} disabled={busy} style={{ width: '100%' }}>
        {busy ? 'Building bundle…' : 'Export bundle'}
      </button>
      {err && <p className="search-hint" style={{ color: 'var(--red)' }}>{err}</p>}
    </div>
  );
}
