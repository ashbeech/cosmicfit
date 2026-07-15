'use client';

import { useMemo } from 'react';
import { validateParagraph, missingPlaceholders } from '@/lib/content/lint';
import type { FieldKind } from '@/lib/content/schema';

/**
 * Ported review_tool.py validation tags. Warnings INFORM, never block. The
 * 50–150-word length rule only applies to full paragraphs; for intros/closings/
 * short prose we show the count neutrally. Placeholder-drop is blueprint-only.
 */
export default function LintWarnings({
  value,
  baselineValue,
  fieldKind,
}: {
  value: string;
  baselineValue: string;
  fieldKind: FieldKind;
}) {
  const v = useMemo(() => validateParagraph(value), [value]);
  const droppedPlaceholders = useMemo(
    () => missingPlaceholders(baselineValue, value),
    [baselineValue, value],
  );

  const isParagraph = fieldKind === 'paragraph';

  return (
    <div className="validation">
      {isParagraph ? (
        <span className={`val-tag ${v.lengthOk ? 'pass' : 'fail'}`}>{v.wordCount} words</span>
      ) : (
        <span className="val-tag">{v.wordCount} words</span>
      )}
      <span className={`val-tag ${v.banned.length ? 'fail' : 'pass'}`}>
        {v.banned.length ? `Banned: ${v.banned.join(', ')}` : 'No banned words'}
      </span>
      <span className={`val-tag ${v.hedging.length ? 'fail' : 'pass'}`}>
        {v.hedging.length ? `Hedging: ${v.hedging.join(', ')}` : 'No hedging'}
      </span>
      {isParagraph && (
        <span className={`val-tag ${v.secondPerson ? 'pass' : 'fail'}`}>
          {v.secondPerson ? '2nd person ✓' : 'Missing 2nd person'}
        </span>
      )}
      <span className={`val-tag ${v.declarative ? 'pass' : 'fail'}`}>
        {v.declarative ? 'Declarative ✓' : 'Ends with ?'}
      </span>
      {v.american.length > 0 && (
        <span className="val-tag warn">US spelling: {v.american.join(', ')}</span>
      )}
      {droppedPlaceholders.length > 0 && (
        <span className="val-tag warn">Dropped placeholder: {droppedPlaceholders.join(', ')}</span>
      )}
    </div>
  );
}
