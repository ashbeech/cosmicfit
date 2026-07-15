import Link from 'next/link';
import { loadGroup } from '@/lib/content/data';
import { FILES, type FileKey } from '@/lib/content/schema';
import EditableField from '@/components/EditableField';

export const dynamic = 'force-dynamic';

function prettyGroup(file: FileKey, groupKey: string): string {
  return file === 'blueprint' ? groupKey.replaceAll('__', ' · ') : groupKey;
}

export default async function EditorPage({
  params,
}: {
  params: { file: string; groupKey: string };
}) {
  const fileKey = params.file as FileKey;
  const groupKey = decodeURIComponent(params.groupKey);
  const meta = FILES[fileKey];

  if (!meta) {
    return <NotFound msg={`Unknown file "${params.file}".`} />;
  }

  if (meta.deferred) {
    return (
      <div>
        <TopBar file={meta.label} group="" />
        <div className="banner warn">
          <strong>{meta.label} — read-only</strong>
          <p style={{ marginTop: 6 }}>{meta.note}</p>
        </div>
      </div>
    );
  }

  const fields = await loadGroup(fileKey, groupKey);
  if (fields.length === 0) {
    return <NotFound msg={`No editable fields for "${groupKey}".`} />;
  }

  return (
    <div>
      <TopBar file={meta.label} group={prettyGroup(fileKey, groupKey)} />
      {fields.map((f) => (
        <EditableField key={f.id} field={f} />
      ))}
    </div>
  );
}

function TopBar({ file, group }: { file: string; group: string }) {
  return (
    <div className="top-bar">
      <div className="crumbs">
        <Link className="plain" href="/">
          {file}
        </Link>
        {group && (
          <>
            <span className="dim"> · </span>
            {group}
          </>
        )}
      </div>
    </div>
  );
}

function NotFound({ msg }: { msg: string }) {
  return (
    <div>
      <div className="top-bar">
        <div className="crumbs">
          <Link className="plain" href="/">
            Home
          </Link>
        </div>
      </div>
      <div className="empty">{msg}</div>
    </div>
  );
}
