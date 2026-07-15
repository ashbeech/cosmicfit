'use client';

import { useEffect, useRef, useState } from 'react';
import { saveFieldAction } from '@/app/(protected)/actions';
import { sectionDisplay, type FieldKind, type FileKey } from '@/lib/content/schema';
import LintWarnings from './LintWarnings';
import FieldHistory from './FieldHistory';
import WordDiff from './WordDiff';

export interface EditableFieldData {
  id: string;
  file: FileKey;
  groupKey: string;
  sectionKey: string | null;
  fieldKind: FieldKind;
  fieldPath: string;
  naturalKey: string;
  baselineValue: string;
  currentValue: string | null;
  version: number;
}

export default function EditableField({ field }: { field: EditableFieldData }) {
  const initial = field.currentValue ?? field.baselineValue;
  const [value, setValue] = useState(initial);
  const [saved, setSaved] = useState(initial);
  const [version, setVersion] = useState(field.version);
  const [status, setStatus] = useState<'idle' | 'saving' | 'saved' | 'error' | 'conflict'>('idle');
  const [message, setMessage] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);
  const [pending, setPending] = useState<{ value: string; label: string } | null>(null);
  const taRef = useRef<HTMLTextAreaElement>(null);

  const dirty = value !== saved;

  function autoGrow() {
    const ta = taRef.current;
    if (!ta) return;
    ta.style.height = 'auto';
    ta.style.height = `${ta.scrollHeight}px`;
  }
  useEffect(autoGrow, [value]);

  async function commit(next: string) {
    setStatus('saving');
    setMessage('');
    const res = await saveFieldAction(field.id, next, version);
    if (res.ok) {
      setSaved(next);
      setValue(next);
      setVersion(res.version ?? version + 1);
      setStatus('saved');
      setRefreshKey((k) => k + 1);
      setTimeout(() => setStatus((s) => (s === 'saved' ? 'idle' : s)), 1600);
    } else if (res.conflict) {
      setStatus('conflict');
      setMessage('Someone else saved this field. Reload to get the latest before editing.');
    } else {
      setStatus('error');
      setMessage(res.error ?? 'Save failed.');
    }
  }

  async function onSave() {
    if (!dirty) return;
    await commit(value);
  }

  function requestRestore(targetValue: string, label: string) {
    setPending({ value: targetValue, label });
  }
  async function confirmRestore() {
    if (!pending) return;
    const target = pending.value;
    setPending(null);
    await commit(target);
  }

  const header = sectionDisplay(field);

  return (
    <div className="section-card" id={`field-${field.id}`}>
      <div className="section-header">
        <span className="section-name">{header}</span>
        <span className="section-meta">{field.fieldKind}</span>
      </div>

      <textarea
        ref={taRef}
        className="field-textarea"
        value={value}
        spellCheck
        onChange={(e) => {
          setValue(e.target.value);
          if (status !== 'idle') setStatus('idle');
        }}
      />

      <LintWarnings value={value} baselineValue={field.baselineValue} fieldKind={field.fieldKind} />

      {pending && (
        <div className="banner warn">
          <strong>Restore to {pending.label}?</strong> This writes a new version (current → target):
          <div style={{ marginTop: 8 }}>
            <WordDiff oldText={value} newText={pending.value} />
          </div>
          <div className="nav-row" style={{ marginTop: 10 }}>
            <button type="button" className="btn btn-danger" onClick={confirmRestore}>
              Confirm restore
            </button>
            <button type="button" className="btn btn-ghost" onClick={() => setPending(null)}>
              Cancel
            </button>
          </div>
        </div>
      )}

      <div className="field-footer">
        <div className="left">
          {status === 'conflict' && <span style={{ color: 'var(--red)', fontSize: 12 }}>{message}</span>}
          {status === 'error' && <span style={{ color: 'var(--red)', fontSize: 12 }}>{message}</span>}
          {status === 'conflict' && (
            <button type="button" className="btn btn-ghost" onClick={() => location.reload()}>
              Reload
            </button>
          )}
        </div>
        <button
          type="button"
          className={`btn ${status === 'saved' ? 'btn-saved' : 'btn-save'}`}
          onClick={onSave}
          disabled={!dirty || status === 'saving'}
        >
          {status === 'saving' ? 'Saving…' : status === 'saved' ? 'Saved ✓' : 'Save'}
        </button>
      </div>

      <FieldHistory
        fieldId={field.id}
        baselineValue={field.baselineValue}
        refreshKey={refreshKey}
        onRestore={requestRestore}
      />
    </div>
  );
}
