/**
 * Seed baselines + field registry.
 *
 * Imports the two v1 copy files — blueprint (blob → Storage) and TarotCards
 * (tree → JSONB) — into dash_baseline, then builds the dash_field registry.
 * Astro is DEFERRED to v2 and intentionally not seeded.
 *
 * Guardrails (all fail LOUD, never half-succeed):
 *   • migration applied?  probes dash_baseline / dash_field first.
 *   • Storage bucket present?  probes `dash-baselines`.
 *   • right file?  asserts the blueprint (and tarot) working-tree sha256 equals
 *     the committed HEAD sha256 — catches seeding a stale/_pre_sg4/dirty cache.
 *     Set SEED_SKIP_GIT_CHECK=1 only if you knowingly seed outside git.
 *   • already seeded?  refuses unless SEED_FORCE=1 (a reseed wipes dash_field,
 *     which cascade-deletes overrides + history — so we make you opt in).
 *
 * Run: `npm run seed`
 */

import {
  serviceClient, die, sha256Hex, gitHeadSha256, readRepoFile,
} from './_lib';
import { FILES, enumerateBlueprint, enumerateTarot, type FieldRecord } from '../lib/content/schema';

const BUCKET = 'dash-baselines';
const CHUNK = 1000;
const supabase = serviceClient();

async function preflightSchema() {
  const { error } = await supabase.from('dash_baseline').select('version_id').limit(1);
  if (error) {
    die(
      `Cannot read table dash_baseline (${error.message}).\n` +
      `→ The migration isn't applied. Paste content-dashboard/supabase/migrations/012_content_dashboard.sql\n` +
      `  into the Supabase SQL editor and run it (README step 1), then retry.`,
    );
  }
}

async function preflightBucket() {
  const { data, error } = await supabase.storage.getBucket(BUCKET);
  if (error || !data) {
    die(
      `Storage bucket "${BUCKET}" not found (${error?.message ?? 'missing'}).\n` +
      `→ Create it: Supabase → Storage → New bucket → name "${BUCKET}", Private (README step 2), then retry.`,
    );
  }
}

async function preflightNotSeeded() {
  const { count, error } = await supabase
    .from('dash_field')
    .select('id', { count: 'exact', head: true });
  if (error) die(`Cannot count dash_field: ${error.message}`);
  if ((count ?? 0) > 0) {
    if (process.env.SEED_FORCE !== '1') {
      die(
        `dash_field already has ${count} rows — the tool looks seeded.\n` +
        `→ Re-seeding wipes dash_field, which cascade-deletes ALL overrides + edit history.\n` +
        `  If that's intended, re-run with SEED_FORCE=1. Otherwise stop.`,
      );
    }
    console.log(`  SEED_FORCE=1 — wiping dash_field (cascades overrides + edit log) and dash_baseline…`);
    await supabase.from('dash_field').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('dash_baseline').delete().neq('version_id', '00000000-0000-0000-0000-000000000000');
  }
}

/** Assert the working file we're about to seed == the committed HEAD version. */
function assertMatchesHead(repoPath: string, workingSha: string, label: string) {
  if (process.env.SEED_SKIP_GIT_CHECK === '1') {
    console.log(`  ⚠ SEED_SKIP_GIT_CHECK=1 — skipping HEAD sha check for ${label}`);
    return;
  }
  const headSha = gitHeadSha256(repoPath);
  if (headSha === null) {
    die(
      `Could not read ${repoPath} at git HEAD to verify the seed source-of-truth.\n` +
      `→ Run from inside the repo, or set SEED_SKIP_GIT_CHECK=1 if you know this is the right file.`,
    );
  }
  if (headSha !== workingSha) {
    die(
      `${label}: working-tree file differs from committed HEAD (possible stale / _pre_sg4 / dirty cache).\n` +
      `  working sha256 = ${workingSha}\n  HEAD    sha256 = ${headSha}\n` +
      `→ Seed ONLY from the committed V2 file. Commit or restore ${repoPath}, then retry.`,
    );
  }
  console.log(`  ✓ ${label} matches committed HEAD (sha ${workingSha.slice(0, 12)}…)`);
}

async function insertBaselineBlob(repoPath: string): Promise<{ versionId: string; tree: any }> {
  const bytes = readRepoFile(repoPath);
  const sha = sha256Hex(bytes);
  assertMatchesHead(repoPath, sha, 'blueprint');
  const tree = JSON.parse(bytes.toString('utf8'));

  const storagePath = `blueprint/${sha}.json`;
  const up = await supabase.storage
    .from(BUCKET)
    .upload(storagePath, bytes, { contentType: 'application/json', upsert: true });
  if (up.error) die(`Storage upload failed: ${up.error.message}`);

  const { data, error } = await supabase
    .from('dash_baseline')
    .insert({ repo_path: repoPath, storage_path: storagePath, sha256: sha, byte_size: bytes.length, tree: null })
    .select('version_id')
    .single();
  if (error || !data) die(`Insert dash_baseline (blueprint) failed: ${error?.message}`);
  console.log(`  ✓ blueprint baseline → Storage ${storagePath} (${bytes.length} bytes)`);
  return { versionId: data.version_id as string, tree };
}

async function insertBaselineInline(repoPath: string, label: string): Promise<{ versionId: string; tree: any }> {
  const bytes = readRepoFile(repoPath);
  const sha = sha256Hex(bytes);
  assertMatchesHead(repoPath, sha, label);
  const tree = JSON.parse(bytes.toString('utf8'));
  const { data, error } = await supabase
    .from('dash_baseline')
    .insert({ repo_path: repoPath, storage_path: null, sha256: sha, byte_size: bytes.length, tree })
    .select('version_id')
    .single();
  if (error || !data) die(`Insert dash_baseline (${label}) failed: ${error?.message}`);
  console.log(`  ✓ ${label} baseline → JSONB (${bytes.length} bytes)`);
  return { versionId: data.version_id as string, tree };
}

function toRows(fields: FieldRecord[], baselineVersionId: string) {
  return fields.map((f) => ({
    file: f.file,
    field_path: f.fieldPath,
    natural_key: f.naturalKey,
    group_key: f.groupKey,
    section_key: f.sectionKey,
    field_kind: f.fieldKind,
    baseline_value: f.baselineValue,
    baseline_version_id: baselineVersionId,
    venus_sign: f.venusSign,
    moon_sign: f.moonSign,
    element: f.element,
  }));
}

async function insertFields(rows: ReturnType<typeof toRows>, label: string) {
  for (let i = 0; i < rows.length; i += CHUNK) {
    const chunk = rows.slice(i, i + CHUNK);
    const { error } = await supabase.from('dash_field').insert(chunk);
    if (error) die(`Insert dash_field (${label}) chunk ${i / CHUNK} failed: ${error.message}`);
    process.stdout.write(`\r    ${label}: ${Math.min(i + CHUNK, rows.length)}/${rows.length} fields`);
  }
  process.stdout.write('\n');
}

async function main() {
  console.log('\n── Seeding Content Dashboard baselines + field registry ──\n');
  console.log('Preflight:');
  await preflightSchema();
  await preflightBucket();
  await preflightNotSeeded();
  console.log('  ✓ schema, bucket, and empty-registry checks passed\n');

  console.log('Blueprint:');
  const bp = await insertBaselineBlob(FILES.blueprint.repoPath);
  const bpFields = enumerateBlueprint(bp.tree);
  console.log(`  enumerated ${bpFields.length} editable fields`);
  await insertFields(toRows(bpFields, bp.versionId), 'blueprint');

  console.log('\nTarotCards:');
  const tarot = await insertBaselineInline(FILES.tarot.repoPath, 'tarot');
  const tarotFields = enumerateTarot(tarot.tree);
  console.log(`  enumerated ${tarotFields.length} editable prose fields`);
  await insertFields(toRows(tarotFields, tarot.versionId), 'tarot');

  console.log('\nAstro:  deferred to v2 — not seeded (engine input, not rendered copy).');
  console.log(`\n✅ Seed complete: ${bpFields.length + tarotFields.length} fields across 2 files.`);
  console.log('   Next: npm run seed:users\n');
}

main().catch((e) => die(e instanceof Error ? e.stack ?? e.message : String(e)));
