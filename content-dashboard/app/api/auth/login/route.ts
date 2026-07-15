import { NextRequest, NextResponse } from 'next/server';
import { getServiceClient } from '@/lib/supabase/server';
import { verifyPassword } from '@/lib/auth/password';
import { signSession, setSessionCookie } from '@/lib/auth/session';

export const runtime = 'nodejs'; // argon2 is a native addon

const MAX_FAILURES = 10; // per window, per username+ip

function clientIp(req: NextRequest): string {
  const fwd = req.headers.get('x-forwarded-for');
  if (fwd) return fwd.split(',')[0].trim();
  return req.headers.get('x-real-ip') ?? 'local';
}

export async function POST(req: NextRequest) {
  let body: { username?: string; password?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'bad_request' }, { status: 400 });
  }
  const username = (body.username ?? '').trim().toLowerCase();
  const password = body.password ?? '';
  if (!username || !password) {
    return NextResponse.json({ error: 'missing_credentials' }, { status: 400 });
  }

  const supabase = getServiceClient();
  const attemptKey = `${username}|${clientIp(req)}`;

  // Persistent rate-limit: checked BEFORE verifying (survives cold starts).
  const { data: failCount, error: rlErr } = await supabase.rpc('dash_login_failure_count', {
    p_attempt_key: attemptKey,
  });
  if (rlErr) {
    // Fail closed on rate-limit infra errors rather than allowing unlimited tries.
    return NextResponse.json({ error: 'rate_limit_unavailable' }, { status: 503 });
  }
  if ((failCount ?? 0) >= MAX_FAILURES) {
    return NextResponse.json({ error: 'too_many_attempts' }, { status: 429 });
  }

  const { data: user } = await supabase
    .from('dash_users')
    .select('id, username, display_name, password_hash')
    .eq('username', username)
    .maybeSingle();

  const ok = user ? await verifyPassword(user.password_hash, password) : false;
  if (!ok || !user) {
    await supabase.rpc('dash_register_login_failure', { p_attempt_key: attemptKey });
    return NextResponse.json({ error: 'invalid_credentials' }, { status: 401 });
  }

  await supabase.rpc('dash_clear_login_failures', { p_attempt_key: attemptKey });

  const token = await signSession({ sub: user.id, username: user.username, name: user.display_name });
  await setSessionCookie(token);
  return NextResponse.json({ ok: true, user: { username: user.username, name: user.display_name } });
}
