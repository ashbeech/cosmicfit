'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import uFuzzy from '@leeoniya/ufuzzy';
import type { IndexField } from '@/lib/content/data';
import { sectionDisplay } from '@/lib/content/schema';

/**
 * Client-side ranked, typo-tolerant fuzzy search over the loaded registry.
 * No per-keystroke network: everything is in-memory. Starts matching at ≥2
 * chars, ~120 ms debounce, results ranked by uFuzzy relevance.
 */
const MAX_RESULTS = 40;
const DEBOUNCE_MS = 120;

function groupLabel(f: IndexField): string {
  const g = f.file === 'blueprint' ? f.groupKey.replaceAll('__', ' · ') : f.groupKey;
  return `${g} — ${sectionDisplay(f)}`;
}

/** React-safe highlight from uFuzzy ranges (flat [s0,e0,s1,e1,…]). */
function highlight(text: string, ranges: number[] | undefined) {
  if (!ranges || ranges.length === 0) return text;
  const out: React.ReactNode[] = [];
  let prev = 0;
  for (let i = 0; i < ranges.length; i += 2) {
    const s = ranges[i];
    const e = ranges[i + 1];
    if (s > prev) out.push(text.slice(prev, s));
    out.push(<mark key={i}>{text.slice(s, e)}</mark>);
    prev = e;
  }
  if (prev < text.length) out.push(text.slice(prev));
  return out;
}

export default function SearchBar({ fields }: { fields: IndexField[] }) {
  const [raw, setRaw] = useState('');
  const [query, setQuery] = useState('');
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setQuery(raw.trim()), DEBOUNCE_MS);
    return () => {
      if (timer.current) clearTimeout(timer.current);
    };
  }, [raw]);

  const uf = useMemo(() => new uFuzzy({ intraMode: 1 }), []);
  const haystack = useMemo(() => fields.map((f) => f.value), [fields]);

  const results = useMemo(() => {
    if (query.length < 2) return null;
    const [idxs, info, order] = uf.search(haystack, query, 1);
    if (!idxs || !order || !info) return [];
    return order.slice(0, MAX_RESULTS).map((oi) => ({
      field: fields[info.idx[oi]],
      ranges: info.ranges[oi] as number[],
    }));
  }, [query, uf, haystack, fields]);

  return (
    <div className="searchbar">
      <input
        className="search-input"
        placeholder="Search copy… (≥2 chars, typo-tolerant)"
        value={raw}
        onChange={(e) => setRaw(e.target.value)}
        aria-label="Search copy"
      />
      {query.length >= 2 && results && (
        <div className="search-results">
          {results.length === 0 && <p className="search-hint">No matches.</p>}
          {results.map(({ field, ranges }) => (
            <Link
              key={field.id}
              className="search-result"
              href={`/editor/${field.file}/${encodeURIComponent(field.groupKey)}#field-${field.id}`}
            >
              <div className="ctx">{groupLabel(field)}</div>
              <div>{highlight(field.value, ranges)}</div>
            </Link>
          ))}
        </div>
      )}
      {raw.trim().length === 1 && <p className="search-hint">Type one more character…</p>}
    </div>
  );
}
