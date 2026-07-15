/**
 * One-time TarotCards normalization generator.
 *
 * TarotCards.json ships today with a mix of inline + multi-line arrays, so it
 * does NOT round-trip under a naive re-dump. This produces the normalized form
 * (indent 4, trailing newline) using the EXPORTER'S OWN Node serializer — the
 * same bytes a future export will emit — so that once this normalization is
 * committed, every export stays a minimal diff.
 *
 * IMPORTANT: it writes to content-dashboard/.generated/ only. It never touches
 * the real Cosmic Fit/Resources/TarotCards.json — the owner reviews the diff and
 * commits it by hand as a separate, one-time change (build order step 9).
 *
 * Run: `npm run normalize:tarot`
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { serialize, sha256Hex as exportSha } from '../lib/content/export';
import { REPO_ROOT, APP_DIR, readRepoFile } from './_lib';

const TAROT = 'Cosmic Fit/Resources/TarotCards.json';

function main() {
  const originalBytes = readRepoFile(TAROT);
  const tree = JSON.parse(originalBytes.toString('utf8'));

  const normalizedText = serialize('tarot', tree);
  const normalizedBytes = Buffer.from(normalizedText, 'utf8');

  const origSha = exportSha(originalBytes);
  const normSha = exportSha(normalizedBytes);

  // Idempotency check: normalizing the normalized output must be a fixed point.
  const reNorm = Buffer.from(serialize('tarot', JSON.parse(normalizedText)), 'utf8');
  const idempotent = exportSha(reNorm) === normSha;

  const outDir = APP_DIR + '.generated';
  mkdirSync(outDir, { recursive: true });
  const outPath = outDir + '/TarotCards.json';
  writeFileSync(outPath, normalizedBytes);

  const delta = normalizedBytes.length - originalBytes.length;
  console.log('\n── TarotCards one-time normalization ──\n');
  console.log(`  original    : ${originalBytes.length} bytes  sha ${origSha.slice(0, 12)}…`);
  console.log(`  normalized  : ${normalizedBytes.length} bytes  sha ${normSha.slice(0, 12)}…`);
  console.log(`  delta       : ${delta >= 0 ? '+' : ''}${delta} bytes (inline arrays expanded to indent 4)`);
  console.log(`  idempotent  : ${idempotent ? 'yes ✓' : 'NO ✗ (investigate before committing)'}`);
  console.log(`  written to  : ${outPath}`);
  console.log('\nNext (owner, one-time reviewed commit):');
  console.log(`  1. diff ${outPath}  ${REPO_ROOT}${TAROT}`);
  console.log(`  2. if the only change is array formatting, copy it over the real file and commit:`);
  console.log(`       cp "${outPath}" "${REPO_ROOT}${TAROT}"`);
  console.log(`  3. after that commit, every dashboard export of TarotCards stays a minimal diff.\n`);

  if (!idempotent) process.exit(1);
}

main();
