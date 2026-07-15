'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

const ERRORS: Record<string, string> = {
  invalid_credentials: 'Wrong username or password.',
  missing_credentials: 'Enter a username and password.',
  too_many_attempts: 'Too many attempts. Wait a few minutes and try again.',
  rate_limit_unavailable: 'Login temporarily unavailable. Try again shortly.',
};

export default function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError('');
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(ERRORS[data.error] ?? 'Login failed.');
        setBusy(false);
        return;
      }
      const next = params.get('next') || '/';
      router.replace(next);
      router.refresh();
    } catch {
      setError('Network error. Try again.');
      setBusy(false);
    }
  }

  return (
    <div className="login-wrap">
      <form className="login-card" onSubmit={submit}>
        <h1>
          <span className="brand">Cosmic Fit</span>
        </h1>
        <p>Content Dashboard — sign in</p>

        <label htmlFor="u">Username</label>
        <input
          id="u"
          autoComplete="username"
          autoFocus
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />

        <label htmlFor="p">Password</label>
        <input
          id="p"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />

        <div className="login-error">{error}</div>

        <button className="btn btn-primary" type="submit" disabled={busy}>
          {busy ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
