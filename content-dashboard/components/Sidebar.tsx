'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import SearchBar from './SearchBar';
import SignFilter, { type Facets, type FacetDim } from './SignFilter';
import ClusterNav, { type NavGroup } from './ClusterNav';
import ExportButton from './ExportButton';
import { FILES, type FileKey } from '@/lib/content/schema';
import type { IndexField } from '@/lib/content/data';

interface IndexResponse {
  fields: IndexField[];
}

// Module-level cache: the registry is a few MB, fetched once per session and
// reused across navigations (the Sidebar lives in the persistent layout).
let cache: Promise<IndexResponse> | null = null;
function loadIndex(): Promise<IndexResponse> {
  if (!cache) {
    cache = fetch('/api/content/index')
      .then((r) => {
        if (!r.ok) throw new Error(String(r.status));
        return r.json();
      })
      .catch((e) => {
        cache = null; // allow retry
        throw e;
      });
  }
  return cache;
}

const FILE_ORDER: FileKey[] = ['blueprint', 'tarot', 'astro'];

export default function Sidebar({ user }: { user: { name: string } }) {
  const router = useRouter();
  const [fields, setFields] = useState<IndexField[] | null>(null);
  const [error, setError] = useState('');
  const [activeFile, setActiveFile] = useState<FileKey>('blueprint');
  const [facets, setFacets] = useState<Facets>({ venus: new Set(), moon: new Set(), element: new Set() });

  useEffect(() => {
    loadIndex()
      .then((d) => setFields(d.fields))
      .catch(() => setError('Could not load content. Is the database seeded?'));
  }, []);

  const fileFields = useMemo(
    () => (fields ?? []).filter((f) => f.file === activeFile),
    [fields, activeFile],
  );

  const available = useMemo(() => {
    const v = new Set<string>();
    const m = new Set<string>();
    const e = new Set<string>();
    for (const f of fileFields) {
      if (f.venusSign) v.add(f.venusSign);
      if (f.moonSign) m.add(f.moonSign);
      if (f.element) e.add(f.element);
    }
    const sort = (s: Set<string>) => [...s].sort();
    return { venus: sort(v), moon: sort(m), element: sort(e) };
  }, [fileFields]);

  const groups: NavGroup[] = useMemo(() => {
    const map = new Map<string, { edited: boolean; count: number; venus: string | null; moon: string | null; element: string | null }>();
    for (const f of fileFields) {
      const g = map.get(f.groupKey) ?? { edited: false, count: 0, venus: f.venusSign, moon: f.moonSign, element: f.element };
      g.count += 1;
      g.edited = g.edited || f.edited;
      map.set(f.groupKey, g);
    }
    let entries = [...map.entries()];
    // facet filter (blueprint only): AND across dims, OR within a dim.
    const passes = (g: { venus: string | null; moon: string | null; element: string | null }) =>
      (facets.venus.size === 0 || (g.venus != null && facets.venus.has(g.venus))) &&
      (facets.moon.size === 0 || (g.moon != null && facets.moon.has(g.moon))) &&
      (facets.element.size === 0 || (g.element != null && facets.element.has(g.element)));
    if (activeFile === 'blueprint') entries = entries.filter(([, g]) => passes(g));
    entries.sort((a, b) => a[0].localeCompare(b[0]));
    return entries.map(([key, g]) => ({
      key,
      label: activeFile === 'blueprint' ? key.replaceAll('__', ' · ') : key,
      edited: g.edited,
      fieldCount: g.count,
    }));
  }, [fileFields, facets, activeFile]);

  function toggleFacet(dim: FacetDim, value: string) {
    setFacets((prev) => {
      const next = { venus: new Set(prev.venus), moon: new Set(prev.moon), element: new Set(prev.element) };
      if (next[dim].has(value)) next[dim].delete(value);
      else next[dim].add(value);
      return next;
    });
  }
  function clearFacets() {
    setFacets({ venus: new Set(), moon: new Set(), element: new Set() });
  }

  async function logout() {
    await fetch('/api/auth/logout', { method: 'POST' });
    router.replace('/login');
    router.refresh();
  }

  const astro = FILES.astro;

  return (
    <div className="sidebar">
      <h1>
        <span className="brand">Cosmic Fit</span>
      </h1>
      <h2>Content Dashboard</h2>

      <div className="sidebar-section-label">Signed in as {user.name}</div>
      <div className="facet-group" style={{ borderBottom: '1px solid var(--border)' }}>
        <div className="nav-row">
          <Link className="btn btn-ghost" href="/changes">
            Changes
          </Link>
          <button className="btn btn-ghost" type="button" onClick={logout}>
            Log out
          </button>
        </div>
        <div style={{ marginTop: 10 }}>
          <ExportButton />
        </div>
      </div>

      {/* File picker */}
      <div className="sidebar-section-label">File</div>
      <div className="facet-group">
        <div className="facet-chips">
          {FILE_ORDER.map((fk) => (
            <span
              key={fk}
              className={`chip ${activeFile === fk ? 'on' : ''}`}
              role="button"
              tabIndex={0}
              onClick={() => setActiveFile(fk)}
              onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && setActiveFile(fk)}
            >
              {FILES[fk].label.split(' — ')[0]}
              {FILES[fk].deferred ? ' · read-only' : ''}
            </span>
          ))}
        </div>
      </div>

      {error && <p className="search-hint" style={{ padding: '12px 16px', color: 'var(--red)' }}>{error}</p>}
      {!fields && !error && <p className="search-hint" style={{ padding: '12px 16px' }}>Loading content…</p>}

      {activeFile === 'astro' ? (
        <div className="banner warn" style={{ margin: 16 }}>
          <strong>{astro.label}</strong>
          <p style={{ marginTop: 6 }}>{astro.note}</p>
        </div>
      ) : (
        fields && (
          <>
            <SearchBar fields={fileFields} />
            {activeFile === 'blueprint' && (
              <SignFilter available={available} selected={facets} onToggle={toggleFacet} onClear={clearFacets} />
            )}
            <div className="sidebar-section-label">
              {groups.length} {activeFile === 'blueprint' ? 'clusters' : 'cards'}
            </div>
            <ClusterNav file={activeFile} groups={groups} />
          </>
        )
      )}
    </div>
  );
}
