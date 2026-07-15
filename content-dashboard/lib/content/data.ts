import 'server-only';
import { getServiceClient } from '@/lib/supabase/server';
import { BLUEPRINT_SECTION_KEYS, type FieldKind, type FileKey } from './schema';

/**
 * Server-only content data access. The editor read path + search index + export
 * all funnel through here. Search is client-side, so `loadRegistryIndex` ships
 * the whole registry once; the editor page uses `loadGroup` for authoritative
 * per-field state (value + optimistic version).
 */

const PAGE = 1000;

/** One registry row for the client search/nav index (value = current or baseline). */
export interface IndexField {
  id: string;
  file: FileKey;
  groupKey: string;
  sectionKey: string | null;
  fieldKind: FieldKind;
  fieldPath: string;
  naturalKey: string;
  venusSign: string | null;
  moonSign: string | null;
  element: string | null;
  value: string;
  edited: boolean; // has a dash_override row (touched at least once)
}

/** Authoritative per-field state for the editor. */
export interface GroupField {
  id: string;
  file: FileKey;
  groupKey: string;
  sectionKey: string | null;
  fieldKind: FieldKind;
  fieldPath: string;
  naturalKey: string;
  baselineValue: string;
  currentValue: string | null;
  version: number; // 0 == never overridden (value is baseline)
}

export interface HistoryEntry {
  id: string;
  oldValue: string | null;
  newValue: string;
  version: number;
  editedBy: string;
  editedAt: string;
}

export interface ChangeEntry extends HistoryEntry {
  fieldId: string;
  fieldPath: string;
  file: string;
  groupKey: string;
}

async function fetchAllOverrides(): Promise<Map<string, { value: string; version: number }>> {
  const supabase = getServiceClient();
  const map = new Map<string, { value: string; version: number }>();
  let from = 0;
  for (;;) {
    const { data, error } = await supabase
      .from('dash_override')
      .select('field_id, current_value, version')
      .range(from, from + PAGE - 1);
    if (error) throw new Error(`load overrides: ${error.message}`);
    for (const r of data ?? []) map.set(r.field_id, { value: r.current_value, version: r.version });
    if (!data || data.length < PAGE) break;
    from += PAGE;
  }
  return map;
}

/** Full registry for the client-side fuzzy index + nav. Paginated (19k+ rows). */
export async function loadRegistryIndex(): Promise<IndexField[]> {
  const supabase = getServiceClient();
  const overrides = await fetchAllOverrides();
  const out: IndexField[] = [];
  let from = 0;
  for (;;) {
    const { data, error } = await supabase
      .from('dash_field')
      .select(
        'id, file, group_key, section_key, field_kind, field_path, natural_key, baseline_value, venus_sign, moon_sign, element',
      )
      .order('id', { ascending: true })
      .range(from, from + PAGE - 1);
    if (error) throw new Error(`load registry: ${error.message}`);
    for (const r of data ?? []) {
      out.push({
        id: r.id,
        file: r.file,
        groupKey: r.group_key,
        sectionKey: r.section_key,
        fieldKind: r.field_kind,
        fieldPath: r.field_path,
        naturalKey: r.natural_key,
        venusSign: r.venus_sign,
        moonSign: r.moon_sign,
        element: r.element,
        value: overrides.get(r.id)?.value ?? r.baseline_value ?? '',
        edited: overrides.has(r.id),
      });
    }
    if (!data || data.length < PAGE) break;
    from += PAGE;
  }
  return out;
}

/** Deterministic display order within a group. */
export function orderRank(f: Pick<GroupField, 'file' | 'sectionKey' | 'fieldKind' | 'fieldPath'>): number {
  if (f.file === 'blueprint') {
    if (f.fieldKind === 'closing') return 100000;
    const base = f.sectionKey?.replace('.intro', '') ?? '';
    const idx = BLUEPRINT_SECTION_KEYS.indexOf(base as (typeof BLUEPRINT_SECTION_KEYS)[number]);
    const sectionRank = (idx < 0 ? BLUEPRINT_SECTION_KEYS.length : idx) * 10;
    return sectionRank + (f.fieldKind === 'intro' ? 0 : 1);
  }
  // tarot: order by the numeric segments of the pointer.
  const nums = f.fieldPath.match(/\d+/g)?.map(Number) ?? [];
  return nums.reduce((acc, n, i) => acc + n * Math.pow(1000, 2 - i), f.sectionKey?.startsWith('styleEdit') ? 500 : 0);
}

/** All fields for one cluster/card, with authoritative value + version. */
export async function loadGroup(file: FileKey, groupKey: string): Promise<GroupField[]> {
  const supabase = getServiceClient();
  const { data: fields, error } = await supabase
    .from('dash_field')
    .select('id, file, group_key, section_key, field_kind, field_path, natural_key, baseline_value')
    .eq('file', file)
    .eq('group_key', groupKey);
  if (error) throw new Error(`load group: ${error.message}`);
  if (!fields || fields.length === 0) return [];

  const ids = fields.map((f) => f.id);
  const overrides = new Map<string, { value: string; version: number }>();
  for (let i = 0; i < ids.length; i += PAGE) {
    const { data: ov, error: ovErr } = await supabase
      .from('dash_override')
      .select('field_id, current_value, version')
      .in('field_id', ids.slice(i, i + PAGE));
    if (ovErr) throw new Error(`load group overrides: ${ovErr.message}`);
    for (const r of ov ?? []) overrides.set(r.field_id, { value: r.current_value, version: r.version });
  }

  const result: GroupField[] = fields.map((f) => {
    const ov = overrides.get(f.id);
    return {
      id: f.id,
      file: f.file,
      groupKey: f.group_key,
      sectionKey: f.section_key,
      fieldKind: f.field_kind,
      fieldPath: f.field_path,
      naturalKey: f.natural_key,
      baselineValue: f.baseline_value ?? '',
      currentValue: ov?.value ?? null,
      version: ov?.version ?? 0,
    };
  });
  result.sort((a, b) => orderRank(a) - orderRank(b));
  return result;
}

export async function loadFieldHistory(fieldId: string): Promise<HistoryEntry[]> {
  const supabase = getServiceClient();
  const { data, error } = await supabase
    .from('dash_edit_log')
    .select('id, old_value, new_value, version, edited_by, edited_at')
    .eq('field_id', fieldId)
    .order('edited_at', { ascending: false });
  if (error) throw new Error(`load history: ${error.message}`);
  return (data ?? []).map((r) => ({
    id: r.id,
    oldValue: r.old_value,
    newValue: r.new_value,
    version: r.version,
    editedBy: r.edited_by,
    editedAt: r.edited_at,
  }));
}

export async function loadChangesFeed(opts: { author?: string; file?: string; limit?: number } = {}): Promise<ChangeEntry[]> {
  const supabase = getServiceClient();
  let q = supabase
    .from('dash_edit_log')
    .select('id, field_id, field_path, file, group_key, old_value, new_value, version, edited_by, edited_at')
    .order('edited_at', { ascending: false })
    .limit(opts.limit ?? 200);
  if (opts.author) q = q.eq('edited_by', opts.author);
  if (opts.file) q = q.eq('file', opts.file);
  const { data, error } = await q;
  if (error) throw new Error(`load changes: ${error.message}`);
  return (data ?? []).map((r) => ({
    id: r.id,
    fieldId: r.field_id,
    fieldPath: r.field_path,
    file: r.file,
    groupKey: r.group_key,
    oldValue: r.old_value,
    newValue: r.new_value,
    version: r.version,
    editedBy: r.edited_by,
    editedAt: r.edited_at,
  }));
}

/** Distinct authors for the /changes filter. */
export async function loadChangeAuthors(): Promise<string[]> {
  const supabase = getServiceClient();
  const { data, error } = await supabase.from('dash_edit_log').select('edited_by');
  if (error) throw new Error(`load authors: ${error.message}`);
  return [...new Set((data ?? []).map((r) => r.edited_by))].sort();
}
