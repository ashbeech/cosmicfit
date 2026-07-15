import { Suspense } from 'react';
import LoginForm from '@/components/LoginForm';

// LoginForm uses useSearchParams (for the ?next= redirect target), which needs a
// Suspense boundary so the page isn't forced into a CSR bail-out at build time.
export default function LoginPage() {
  return (
    <Suspense fallback={<div className="login-wrap" />}>
      <LoginForm />
    </Suspense>
  );
}
