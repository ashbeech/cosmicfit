'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { FileKey } from '@/lib/content/schema';

export interface NavGroup {
  key: string;
  label: string;
  edited: boolean;
  fieldCount: number;
}

/** The cluster/card list for the active file. */
export default function ClusterNav({ file, groups }: { file: FileKey; groups: NavGroup[] }) {
  const pathname = usePathname();
  if (groups.length === 0) {
    return <p className="search-hint" style={{ padding: '12px 16px' }}>No groups.</p>;
  }
  return (
    <div>
      {groups.map((g) => {
        const href = `/editor/${file}/${encodeURIComponent(g.key)}`;
        const active = pathname === href || pathname === `/editor/${file}/${g.key}`;
        return (
          <Link key={g.key} className={`cluster-item${active ? ' active' : ''}`} href={href}>
            <span className="label">{g.label}</span>
            <span className={`badge${g.edited ? ' complete' : ''}`}>
              {g.edited ? 'edited' : g.fieldCount}
            </span>
          </Link>
        );
      })}
    </div>
  );
}
