'use client';

import { useState } from 'react';

/**
 * POST /api/export → the route reconstructs the bundle, uploads the
 * byte-identical zip to Storage, and returns a short-lived signed URL. We then
 * download the exact bytes straight from Storage (no size limit, and the file
 * that lands on disk is byte-for-byte the reconstructed bundle).
 */
export default function ExportButton() {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [done, setDone] = useState<{ url: string; name: string; version: number; changed: number } | null>(null);

  async function run() {
    setBusy(true);
    setErr('');
    setDone(null);
    try {
      const res = await fetch('/api/export', { method: 'POST' });
      const data = await res.json().catch(() => ({}));
      if (!res.ok || !data.downloadUrl) {
        setErr(data.error ?? `Export failed (${res.status})`);
        setBusy(false);
        return;
      }
      // Trigger the download from the signed Storage URL. The URL carries a
      // Content-Disposition (via ?download=), so the browser saves it with the
      // right filename even cross-origin.
      const a = document.createElement('a');
      a.href = data.downloadUrl;
      a.download = data.filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setDone({ url: data.downloadUrl, name: data.filename, version: data.versionId, changed: data.changedFieldCount });
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
      {done && (
        <p className="search-hint">
          v{done.version} · {done.changed} changed field{done.changed === 1 ? '' : 's'} ·{' '}
          {/* fallback link if the auto-download was blocked (valid ~1h) */}
          <a className="plain" href={done.url}>
            download {done.name}
          </a>
        </p>
      )}
    </div>
  );
}
