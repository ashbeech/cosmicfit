import 'server-only';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { env } from '@/lib/env';

/**
 * Service-role Supabase client — SERVER ONLY.
 *
 * The `import 'server-only'` above makes Next fail the build if this module is
 * ever pulled into a Client Component bundle, so the service-role key (which
 * bypasses RLS) can never reach the browser. All `dash_*` access goes through
 * here from Server Components / route handlers / Server Actions.
 */
let _client: SupabaseClient | null = null;

export function getServiceClient(): SupabaseClient {
  if (_client) return _client;
  _client = createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return _client;
}
