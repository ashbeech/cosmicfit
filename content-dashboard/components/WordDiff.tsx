'use client';

import { diffWords } from 'diff';

/** Word-level diff: insertions green (<ins>), deletions struck red (<del>). */
export default function WordDiff({ oldText, newText }: { oldText: string; newText: string }) {
  const parts = diffWords(oldText ?? '', newText ?? '');
  return (
    <div className="worddiff">
      {parts.map((p, i) => {
        if (p.added) return <ins key={i}>{p.value}</ins>;
        if (p.removed) return <del key={i}>{p.value}</del>;
        return <span key={i}>{p.value}</span>;
      })}
    </div>
  );
}
