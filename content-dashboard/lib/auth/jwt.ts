/**
 * Edge-safe session crypto (pure jose, no next/headers). Imported by both the
 * edge middleware and Node route handlers. Cookie read/write lives in
 * ./session.ts (next/headers) to keep this module runtime-agnostic.
 */

import { SignJWT, jwtVerify } from 'jose';
import { env } from '@/lib/env';

export const SESSION_COOKIE = 'cf_dash';
export const MAX_AGE_SECONDS = 60 * 60 * 24 * 7; // 7 days

export interface SessionPayload {
  sub: string; // dash_users.id
  username: string;
  name: string; // display_name
}

function key(): Uint8Array {
  return new TextEncoder().encode(env.sessionSecret);
}

export async function signSession(payload: SessionPayload): Promise<string> {
  return new SignJWT({ username: payload.username, name: payload.name })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(payload.sub)
    .setIssuedAt()
    .setExpirationTime(`${MAX_AGE_SECONDS}s`)
    .sign(key());
}

/** Verify a token; returns the payload or null. Edge- and Node-safe. */
export async function verifyToken(token: string | undefined): Promise<SessionPayload | null> {
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, key());
    if (!payload.sub || typeof payload.username !== 'string') return null;
    return {
      sub: payload.sub,
      username: payload.username,
      name: (payload.name as string) ?? payload.username,
    };
  } catch {
    return null;
  }
}
