/**
 * Auth gate for every page and every /api/* route. The public URL means this is
 * the real security boundary, so the default is DENY: anything not explicitly
 * public requires a valid session cookie.
 *
 * Public: /login and /api/auth/login (you need to be able to reach the door).
 * Everything else → unauthenticated pages redirect to /login; unauthenticated
 * /api/* get a 401 JSON (no redirect, so fetches fail cleanly).
 */

import { NextRequest, NextResponse } from 'next/server';
import { SESSION_COOKIE, verifyToken } from '@/lib/auth/jwt';

const PUBLIC_PATHS = new Set(['/login', '/api/auth/login']);

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  if (PUBLIC_PATHS.has(pathname)) {
    return NextResponse.next();
  }

  const session = await verifyToken(req.cookies.get(SESSION_COOKIE)?.value);
  if (session) {
    return NextResponse.next();
  }

  if (pathname.startsWith('/api/')) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const loginUrl = new URL('/login', req.url);
  if (pathname !== '/') loginUrl.searchParams.set('next', pathname);
  return NextResponse.redirect(loginUrl);
}

export const config = {
  // Run on everything except Next internals and static assets.
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:png|jpg|jpeg|svg|ico|woff2?)$).*)'],
};
