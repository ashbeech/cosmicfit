/**
 * Seed the two operator accounts (maria, ash) with argon2id password hashes.
 * Passwords come from env (SEED_MARIA_PASSWORD / SEED_ASH_PASSWORD) and are
 * NEVER committed. Idempotent: upsert by username (re-run to rotate a password).
 *
 * Run: `npm run seed:users`
 */

import { hash } from '@node-rs/argon2';
import { serviceClient, die, requireEnv } from './_lib';

// Algorithm.Argon2id === 2 (const enum; use the literal to satisfy isolatedModules).
const ARGON2ID = 2;
const supabase = serviceClient();

const ACCOUNTS = [
  { username: 'maria', display_name: 'Maria', passwordEnv: 'SEED_MARIA_PASSWORD' },
  { username: 'ash', display_name: 'Ash', passwordEnv: 'SEED_ASH_PASSWORD' },
];

async function preflight() {
  const { error } = await supabase.from('dash_users').select('id').limit(1);
  if (error) {
    die(
      `Cannot read table dash_users (${error.message}).\n` +
      `→ Apply the migration first (README step 1), then retry.`,
    );
  }
}

async function main() {
  console.log('\n── Seeding operator accounts ──\n');
  await preflight();

  for (const acct of ACCOUNTS) {
    const password = requireEnv(acct.passwordEnv);
    if (password.length < 8) die(`${acct.passwordEnv} is too short — use a strong random password.`);
    const password_hash = await hash(password, { algorithm: ARGON2ID });
    const { error } = await supabase
      .from('dash_users')
      .upsert(
        { username: acct.username, display_name: acct.display_name, password_hash },
        { onConflict: 'username' },
      );
    if (error) die(`Upsert user ${acct.username} failed: ${error.message}`);
    console.log(`  ✓ ${acct.username} (${acct.display_name}) — argon2id hash set`);
  }

  console.log('\n✅ Users seeded. Hand each password to its owner out-of-band. Then: npm run dev\n');
}

main().catch((e) => die(e instanceof Error ? e.stack ?? e.message : String(e)));
