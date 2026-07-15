'use server';

import { getServiceClient } from '@/lib/supabase/server';
import { getSession } from '@/lib/auth/session';

export interface SaveResult {
  ok: boolean;
  conflict: boolean;
  version?: number;
  error?: string;
}

/**
 * Save (or Restore — a restore is just a forward save of the target value).
 * Atomic via dash_save_field: optimistic version guard + override upsert +
 * append to dash_edit_log, all server-side. A version mismatch returns
 * {ok:false, conflict:true} so the UI can prompt a reload instead of clobbering.
 */
export async function saveFieldAction(
  fieldId: string,
  newValue: string,
  expectedVersion: number,
): Promise<SaveResult> {
  const session = await getSession();
  if (!session) return { ok: false, conflict: false, error: 'unauthorized' };

  const supabase = getServiceClient();
  const { data, error } = await supabase.rpc('dash_save_field', {
    p_field_id: fieldId,
    p_new_value: newValue,
    p_expected_version: expectedVersion,
    p_editor: session.username,
  });
  if (error) return { ok: false, conflict: false, error: error.message };

  const r = data as { ok: boolean; conflict: boolean; version?: number; error?: string };
  return { ok: r.ok, conflict: r.conflict, version: r.version, error: r.error };
}
