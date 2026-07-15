import 'server-only';
import { hash, verify } from '@node-rs/argon2';

// Algorithm.Argon2id === 2 (const enum; use the literal to satisfy isolatedModules).
const ARGON2ID = 2;

/** argon2id — matches the hashes written by scripts/seed-users.ts. Node runtime only. */
export function hashPassword(password: string): Promise<string> {
  return hash(password, { algorithm: ARGON2ID });
}

export function verifyPassword(storedHash: string, password: string): Promise<boolean> {
  return verify(storedHash, password).catch(() => false);
}
