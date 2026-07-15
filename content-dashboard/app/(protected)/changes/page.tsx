import Link from 'next/link';
import { loadChangesFeed, loadChangeAuthors } from '@/lib/content/data';
import { FILES, sectionDisplay, type FileKey } from '@/lib/content/schema';
import WordDiff from '@/components/WordDiff';

export const dynamic = 'force-dynamic';

function contextLabel(file: string, groupKey: string, fieldPath: string): string {
  const g = file === 'blueprint' ? groupKey.replaceAll('__', ' · ') : groupKey;
  // derive a section-ish label from the trailing pointer token
  const tokens = fieldPath.split('/').filter(Boolean);
  const leaf = tokens[tokens.length - 1] ?? '';
  return `${g} — ${leaf}`;
}

export default async function ChangesPage({
  searchParams,
}: {
  searchParams: { author?: string; file?: string };
}) {
  const author = searchParams.author;
  const file = searchParams.file;
  const [feed, authors] = await Promise.all([
    loadChangesFeed({ author, file, limit: 200 }),
    loadChangeAuthors(),
  ]);

  const fileChips: (FileKey | undefined)[] = [undefined, 'blueprint', 'tarot'];
  const q = (next: { author?: string; file?: string }) => {
    const p = new URLSearchParams();
    if (next.author) p.set('author', next.author);
    if (next.file) p.set('file', next.file);
    const s = p.toString();
    return s ? `/changes?${s}` : '/changes';
  };

  return (
    <div>
      <div className="top-bar">
        <div className="crumbs">
          <Link className="plain" href="/">
            Home
          </Link>
          <span className="dim"> · </span>Changes
        </div>
      </div>

      <div className="section-card" style={{ padding: 12 }}>
        <div className="facet-title">Author</div>
        <div className="facet-chips" style={{ marginBottom: 10 }}>
          <Link className={`chip ${!author ? 'on' : ''}`} href={q({ file })}>
            All
          </Link>
          {authors.map((a) => (
            <Link key={a} className={`chip ${author === a ? 'on' : ''}`} href={q({ author: a, file })}>
              {a}
            </Link>
          ))}
        </div>
        <div className="facet-title">File</div>
        <div className="facet-chips">
          {fileChips.map((fk) => (
            <Link
              key={fk ?? 'all'}
              className={`chip ${file === fk || (!file && !fk) ? 'on' : ''}`}
              href={q({ author, file: fk })}
            >
              {fk ? FILES[fk].label.split(' — ')[0] : 'All'}
            </Link>
          ))}
        </div>
      </div>

      {feed.length === 0 && <div className="empty">No changes yet.</div>}

      {feed.map((c) => (
        <div className="section-card" key={c.id}>
          <div className="section-header">
            <span className="section-name" style={{ fontSize: 13 }}>
              {contextLabel(c.file, c.groupKey, c.fieldPath)}
            </span>
            <span className="section-meta">
              v{c.version} · {c.editedBy} · {new Date(c.editedAt).toLocaleString()}
            </span>
          </div>
          <WordDiff oldText={c.oldValue ?? ''} newText={c.newValue} />
          <div className="field-footer" style={{ marginTop: 8 }}>
            <span className="section-meta">{FILES[c.file as FileKey]?.label ?? c.file}</span>
            <Link
              className="btn btn-ghost"
              href={`/editor/${c.file}/${encodeURIComponent(c.groupKey)}#field-${c.fieldId}`}
            >
              Open field
            </Link>
          </div>
        </div>
      ))}
    </div>
  );
}
