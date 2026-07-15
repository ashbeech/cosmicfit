/**
 * Environment access + validation. No 'server-only' here so it can be imported
 * from edge middleware (SESSION_SECRET) and Node route handlers alike. Never
 * expose these to the client — none are NEXT_PUBLIC_.
 */

export function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v || v.trim() === '') {
    throw new Error(
      `Missing required env var ${name}. Copy .env.local.example → .env.local and fill it in.`,
    );
  }
  return v;
}

export const env = {
  get supabaseUrl() {
    return requireEnv('SUPABASE_URL');
  },
  /** Canonical name across the repo's tooling. Server-only; bypasses RLS. */
  get supabaseServiceRoleKey() {
    return requireEnv('SUPABASE_SERVICE_ROLE_KEY');
  },
  get sessionSecret() {
    return requireEnv('SESSION_SECRET');
  },
};
