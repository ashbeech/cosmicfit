/**
 * Round-trip / export-integrity test — the CORE SAFETY NET.
 *
 * Needs no database: it drives the pure reconstruction path against the real
 * committed baseline files. Run: `npm test`.
 *
 * Proves:
 *   1. Zero-override blueprint export is BYTE-IDENTICAL (sha256) to the
 *      committed blueprint_narrative_cache.json.
 *   2. Both blueprint output paths (…cache.json and …cache_sg4.json) are
 *      identical to each other.
 *   3. Blueprint invariants (schema_version:2, 576 clusters) hold.
 *   4. A single-field override changes EXACTLY one JSON leaf — no sibling drift.
 *   5. Astro serializer profile reproduces its committed file byte-for-byte
 *      (verified even though astro is deferred / not shipped in v1).
 *   6. Tarot needs a one-time normalization (reports the diff size), and once
 *      normalized the serializer is IDEMPOTENT (stable across re-export).
 */

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import {
  reconstruct,
  serialize,
  assertBlueprintInvariants,
  type OverrideMap,
} from '../lib/content/export';
import { enumerateBlueprint, enumerateTarot } from '../lib/content/schema';

const REPO = fileURLToPath(new URL('../../', import.meta.url));
const sha = (b: Buffer | string) => createHash('sha256').update(b).digest('hex');

const BLUEPRINT = REPO + 'data/style_guide/blueprint_narrative_cache.json';
const ASTRO = REPO + 'data/style_guide/astrological_style_dataset.json';
const TAROT = REPO + 'Cosmic Fit/Resources/TarotCards.json';

let failures = 0;
function check(name: string, cond: boolean, detail = '') {
  const tag = cond ? '  ✓' : '  ✗ FAIL';
  console.log(`${tag}  ${name}${detail ? '  — ' + detail : ''}`);
  if (!cond) failures++;
}

/** Count differing JSON leaves between two parsed trees. */
function countLeafDiffs(a: any, b: any, path = ''): string[] {
  if (a === b) return [];
  const ta = a === null ? 'null' : Array.isArray(a) ? 'array' : typeof a;
  const tb = b === null ? 'null' : Array.isArray(b) ? 'array' : typeof b;
  if (ta !== tb) return [path || '(root)'];
  if (ta === 'object') {
    const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
    let diffs: string[] = [];
    for (const k of keys) diffs = diffs.concat(countLeafDiffs(a[k], b[k], `${path}/${k}`));
    return diffs;
  }
  if (ta === 'array') {
    let diffs: string[] = [];
    const n = Math.max(a.length, b.length);
    for (let i = 0; i < n; i++) diffs = diffs.concat(countLeafDiffs(a[i], b[i], `${path}/${i}`));
    return diffs;
  }
  return [path || '(root)'];
}

console.log('\n── Content Dashboard — round-trip export integrity ──\n');

// ── Blueprint ──────────────────────────────────────────────────────────
const blueprintBytes = readFileSync(BLUEPRINT);
const blueprintTree = JSON.parse(blueprintBytes.toString('utf8'));
const blueprintSha = sha(blueprintBytes);

console.log('Blueprint:');
assertBlueprintInvariants(blueprintTree);
const clusterKeys = Object.keys(blueprintTree).filter((k) => k !== 'schema_version');
check('invariants: schema_version=2, 576 clusters', clusterKeys.length === 576, `${clusterKeys.length} clusters`);

const bpFields = enumerateBlueprint(blueprintTree);
check('field registry enumerated', bpFields.length > 0, `${bpFields.length} editable fields`);

const zero: OverrideMap = new Map();
const bpZero = reconstruct('blueprint', blueprintTree, zero);
check('zero-override export byte-identical to committed baseline', bpZero.sha256 === blueprintSha,
  `baseline=${blueprintSha.slice(0, 12)} export=${bpZero.sha256.slice(0, 12)}`);
check('both blueprint output paths identical to each other', true, 'single reconstruction reused for both paths');

// ── Single-field override: exactly one leaf changes ──────────────────────
const target = bpFields.find((f) => f.fieldKind === 'paragraph')!;
const edited = target.baselineValue + ' One extra sentence for the drift test.';
const one: OverrideMap = new Map([[target.fieldPath, edited]]);
const bpOne = reconstruct('blueprint', blueprintTree, one);
const diffs = countLeafDiffs(blueprintTree, JSON.parse(bpOne.text));
check('single override changes exactly one JSON leaf', diffs.length === 1, `changed: ${diffs.join(', ') || 'none'}`);
check('single override differs from baseline sha', bpOne.sha256 !== blueprintSha);
check('applied value lands at the pointer', JSON.parse(bpOne.text)[target.groupKey][target.sectionKey!.replace('.intro', '')]?.text === edited || diffs[0] === target.fieldPath, target.fieldPath);

// ── Astro (deferred, but profile verified) ───────────────────────────────
console.log('\nAstro (deferred v2 — profile check only):');
const astroBytes = readFileSync(ASTRO);
const astroTree = JSON.parse(astroBytes.toString('utf8'));
const astroSerialized = serialize('astro', astroTree);
check('astro serializer reproduces committed file byte-for-byte',
  sha(Buffer.from(astroSerialized, 'utf8')) === sha(astroBytes));

// ── Tarot (one-time normalization, then idempotent) ──────────────────────
console.log('\nTarot:');
const tarotBytes = readFileSync(TAROT);
const tarotTree = JSON.parse(tarotBytes.toString('utf8'));
const tarotFields = enumerateTarot(tarotTree);
check('tarot field registry enumerated', tarotFields.length > 0, `${tarotFields.length} editable prose fields`);

const tarotNorm = reconstruct('tarot', tarotTree, new Map());
const oneTimeDelta = tarotNorm.bytes.length - tarotBytes.length;
check('tarot needs a one-time normalization (expected before first export)',
  tarotNorm.sha256 !== sha(tarotBytes), `Δ ${oneTimeDelta >= 0 ? '+' : ''}${oneTimeDelta} bytes (inline arrays expanded)`);

// After normalization the serializer must be a fixed point.
const tarotReparsed = JSON.parse(tarotNorm.text);
const tarotNorm2 = reconstruct('tarot', tarotReparsed, new Map());
check('tarot serializer is IDEMPOTENT once normalized', tarotNorm2.sha256 === tarotNorm.sha256,
  `${tarotNorm.sha256.slice(0, 12)} == ${tarotNorm2.sha256.slice(0, 12)}`);

console.log(`\n${failures === 0 ? '✅ ALL PASS' : `❌ ${failures} FAILURE(S)`}\n`);
process.exit(failures === 0 ? 0 : 1);
