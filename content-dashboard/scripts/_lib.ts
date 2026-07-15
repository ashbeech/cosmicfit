/**
 * Shared helpers for the standalone seed/normalize scripts. These run under
 * `tsx` (not Next), so they build their own Supabase client from `.env.local`
 * and never import the `server-only`-guarded runtime client.
 */

import { config as loadEnv } from 'dotenv';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';

// Load .env.local (then .env as fallback) from the content-dashboard dir.
loadEnv({ path: '.env.local' });
loadEnv({ path: '.env' });

/** content-dashboard/ */
export const APP_DIR = fileURLToPath(new URL('../', import.meta.url));
/** repo root (one level up from content-dashboard). */
export const REPO_ROOT = fileURLToPath(new URL('../../', import.meta.url));

export function die(msg: string): never {
  console.error(`\n✗ ${msg}\n`);
  process.exit(1);
}

export function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v || v.trim() === '') die(`Missing env var ${name}. Fill it in .env.local (see .env.local.example).`);
  return v as string;
}

export function serviceClient(): SupabaseClient {
  const url = requireEnv('SUPABASE_URL');
  const key = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
  return createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
}

export function sha256Hex(buf: Buffer | string): string {
  return createHash('sha256').update(buf).digest('hex');
}

/** sha256 of the file as committed at HEAD, or null if git/lookup fails. */
export function gitHeadSha256(repoRelPath: string): string | null {
  try {
    const bytes = execFileSync('git', ['-C', REPO_ROOT, 'show', `HEAD:${repoRelPath}`], {
      maxBuffer: 64 * 1024 * 1024,
    });
    return sha256Hex(bytes);
  } catch {
    return null;
  }
}

export function readRepoFile(repoRelPath: string): Buffer {
  return readFileSync(REPO_ROOT + repoRelPath);
}
