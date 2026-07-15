/**
 * Idempotent Storage-bucket setup + connectivity check.
 *
 * Creates the private `dash-baselines` bucket via the service-role key (the same
 * thing you can do by hand in Supabase → Storage → New bucket). Getting/creating
 * the bucket also proves SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY are valid.
 *
 * Run: `npm run setup:storage`
 */

import { serviceClient, die } from './_lib';

const BUCKET = 'dash-baselines';

async function main() {
  const supabase = serviceClient();

  // Connectivity + existence probe.
  const { data: existing, error: getErr } = await supabase.storage.getBucket(BUCKET);
  if (existing) {
    console.log(`  ✓ bucket "${BUCKET}" already exists (${existing.public ? 'PUBLIC ⚠' : 'private'})`);
    return;
  }
  // getBucket returns an error for "not found" — only treat auth/URL failures as fatal.
  if (getErr && /Invalid|JWT|apikey|fetch failed|ENOTFOUND|Unauthorized/i.test(getErr.message)) {
    die(`Cannot reach Supabase (${getErr.message}). Check SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY in .env.local.`);
  }

  const { error } = await supabase.storage.createBucket(BUCKET, { public: false });
  if (error) die(`Create bucket "${BUCKET}" failed: ${error.message}`);
  console.log(`  ✓ created private bucket "${BUCKET}"`);
}

main().catch((e) => die(e instanceof Error ? e.message : String(e)));
