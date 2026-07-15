import 'server-only';
import { getServiceClient } from '@/lib/supabase/server';
import { FILES, type FileKey } from './schema';

const BUCKET = 'dash-baselines';
const PAGE = 1000;

export interface BaselineTree {
  tree: unknown;
  versionId: string;
  sha256: string;
  repoPath: string;
}

/** Latest seeded baseline tree for a file (JSONB inline, or downloaded blob). */
export async function loadBaselineTree(file: FileKey): Promise<BaselineTree> {
  const supabase = getServiceClient();
  const repoPath = FILES[file].repoPath;
  const { data: row, error } = await supabase
    .from('dash_baseline')
    .select('version_id, storage_path, sha256, tree')
    .eq('repo_path', repoPath)
    .order('imported_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw new Error(`load baseline (${file}): ${error.message}`);
  if (!row) throw new Error(`No baseline seeded for ${file} (${repoPath}). Run npm run seed.`);

  let tree: unknown;
  if (row.tree != null) {
    tree = row.tree;
  } else if (row.storage_path) {
    const dl = await supabase.storage.from(BUCKET).download(row.storage_path);
    if (dl.error || !dl.data) throw new Error(`download baseline blob failed: ${dl.error?.message}`);
    const buf = Buffer.from(await dl.data.arrayBuffer());
    tree = JSON.parse(buf.toString('utf8'));
  } else {
    throw new Error(`baseline row for ${file} has neither tree nor storage_path`);
  }
  return { tree, versionId: row.version_id, sha256: row.sha256, repoPath };
}

export interface ExportOverride {
  file: FileKey;
  fieldPath: string;
  naturalKey: string;
  value: string;
  editedBy: string;
  editedAt: string;
}

/** Every current override, joined to its field's pointer + natural key. */
export async function loadOverridesForExport(): Promise<ExportOverride[]> {
  const supabase = getServiceClient();

  // 1) all overrides
  const overrides: Array<{ field_id: string; current_value: string; updated_by: string; updated_at: string }> = [];
  let from = 0;
  for (;;) {
    const { data, error } = await supabase
      .from('dash_override')
      .select('field_id, current_value, updated_by, updated_at')
      .range(from, from + PAGE - 1);
    if (error) throw new Error(`load overrides: ${error.message}`);
    overrides.push(...(data ?? []));
    if (!data || data.length < PAGE) break;
    from += PAGE;
  }
  if (overrides.length === 0) return [];

  // 2) fields for those overrides
  const ids = overrides.map((o) => o.field_id);
  const fieldMap = new Map<string, { file: FileKey; field_path: string; natural_key: string }>();
  for (let i = 0; i < ids.length; i += PAGE) {
    const { data, error } = await supabase
      .from('dash_field')
      .select('id, file, field_path, natural_key')
      .in('id', ids.slice(i, i + PAGE));
    if (error) throw new Error(`load fields for export: ${error.message}`);
    for (const f of data ?? []) fieldMap.set(f.id, { file: f.file, field_path: f.field_path, natural_key: f.natural_key });
  }

  return overrides
    .map((o) => {
      const f = fieldMap.get(o.field_id);
      if (!f) return null;
      return {
        file: f.file,
        fieldPath: f.field_path,
        naturalKey: f.natural_key,
        value: o.current_value,
        editedBy: o.updated_by,
        editedAt: o.updated_at,
      } satisfies ExportOverride;
    })
    .filter((x): x is ExportOverride => x !== null);
}
