import { redirect } from 'next/navigation';
import { getSession } from '@/lib/auth/session';
import Sidebar from '@/components/Sidebar';

export const dynamic = 'force-dynamic';

export default async function ProtectedLayout({ children }: { children: React.ReactNode }) {
  // Defense in depth: middleware already gates this, but re-check so we always
  // have a real session (and the user's name for the nav).
  const session = await getSession();
  if (!session) redirect('/login');

  return (
    <div className="shell">
      <Sidebar user={{ name: session.name }} />
      <main className="main">{children}</main>
    </div>
  );
}
