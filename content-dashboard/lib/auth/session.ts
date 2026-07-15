/**
 * Cookie helpers (Route Handlers / Server Actions / Server Components). These
 * use next/headers, so they must NOT be imported by the edge middleware — the
 * middleware reads the cookie off the NextRequest and calls verifyToken from
 * ./jwt.ts directly.
 */

import { cookies } from 'next/headers';
import { SESSION_COOKIE, MAX_AGE_SECONDS, verifyToken, type SessionPayload } from './jwt';

export { SESSION_COOKIE, signSession, verifyToken } from './jwt';
export type { SessionPayload } from './jwt';

/** `Secure` in production; relaxed on localhost http for local dev. */
function cookieOptions(maxAge: number = MAX_AGE_SECONDS) {
  return {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax' as const,
    path: '/',
    maxAge,
  };
}

export async function setSessionCookie(token: string): Promise<void> {
  cookies().set(SESSION_COOKIE, token, cookieOptions());
}

export async function clearSessionCookie(): Promise<void> {
  cookies().set(SESSION_COOKIE, '', cookieOptions(0));
}

/** Current session from request cookies (Server Components / Route Handlers). */
export async function getSession(): Promise<SessionPayload | null> {
  return verifyToken(cookies().get(SESSION_COOKIE)?.value);
}
