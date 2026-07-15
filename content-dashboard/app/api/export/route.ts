import { NextRequest, NextResponse } from 'next/server';
import { getServiceClient } from '@/lib/supabase/server';
import { getSession } from '@/lib/auth/session';
import { loadBaselineTree, loadOverridesForExport } from '@/lib/content/exportData';
import {
  reconstruct,
  assertBlueprintInvariants,
  blueprintBundleFiles,
  tarotBundleFile,
  buildManifest,
  serializeManifest,
  type OverrideMap,
  type ManifestChangedField,
  type BundleFile,
} from '@/lib/content/export';
import { makeZip, type ZipEntry } from '@/lib/content/zip';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * Reconstruct the content files from the frozen baselines + current overrides,
 * package them (both blueprint files + TarotCards + manifest) as a downloadable
 * zip, and record the export in dash_content_versions.
 *
 * A zero-override export reproduces the committed blueprint byte-for-byte (the
 * safety net, proven by scripts/test-roundtrip.ts). TarotCards comes out
 * normalized (indent 4) — the first drop carries the one-time normalization.
 */
export async function POST(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  let label = '';
  try {
    const body = await req.json();
    if (typeof body?.label === 'string') label = body.label;
  } catch {
    /* no body is fine */
  }

  try {
    const supabase = getServiceClient();

    const [blueprintBase, tarotBase] = await Promise.all([
      loadBaselineTree('blueprint'),
      loadBaselineTree('tarot'),
    ]);
    const overrides = await loadOverridesForExport();

    // Split overrides into per-file pointer→value maps.
    const bpMap: OverrideMap = new Map();
    const tarotMap: OverrideMap = new Map();
    const changedFields: ManifestChangedField[] = [];
    for (const o of overrides) {
      if (o.file === 'blueprint') bpMap.set(o.fieldPath, o.value);
      else if (o.file === 'tarot') tarotMap.set(o.fieldPath, o.value);
      changedFields.push({
        file: o.file,
        fieldPath: o.fieldPath,
        naturalKey: o.naturalKey,
        editedBy: o.editedBy,
        editedAt: o.editedAt,
      });
    }

    // Reconstruct (strict: a non-anchoring pointer is surfaced, not dropped).
    const bp = reconstruct('blueprint', blueprintBase.tree, bpMap);
    assertBlueprintInvariants(bp.tree, Object.keys(blueprintBase.tree as Record<string, unknown>));
    const tarot = reconstruct('tarot', tarotBase.tree, tarotMap);

    const files: BundleFile[] = [...blueprintBundleFiles(bp), tarotBundleFile(tarot)];

    const fileSha: Record<string, string> = {};
    for (const f of files) fileSha[f.repoPath] = f.sha256;

    const createdAt = new Date().toISOString();

    // Record the export version first (to obtain version_id for the manifest).
    const { data: versionRow, error: verErr } = await supabase
      .from('dash_content_versions')
      .insert({
        editor: session.username,
        label,
        manifest: {},
        file_sha256: fileSha,
        changed_field_count: changedFields.length,
        status: 'exported',
      })
      .select('version_id')
      .single();
    if (verErr || !versionRow) {
      return NextResponse.json({ error: `record version failed: ${verErr?.message}` }, { status: 500 });
    }
    const versionId = versionRow.version_id as number;

    const manifest = buildManifest({
      createdAt,
      versionId,
      editor: session.username,
      label,
      changedFields,
      files,
    });
    await supabase.from('dash_content_versions').update({ manifest }).eq('version_id', versionId);

    const entries: ZipEntry[] = [
      ...files.map((f) => ({ name: f.repoPath, data: f.bytes })),
      { name: 'manifest.json', data: Buffer.from(serializeManifest(manifest), 'utf8') },
    ];
    const zip = makeZip(entries);

    return new NextResponse(new Uint8Array(zip), {
      status: 200,
      headers: {
        'Content-Type': 'application/zip',
        'Content-Disposition': `attachment; filename="content-export-v${versionId}.zip"`,
        'Content-Length': String(zip.length),
      },
    });
  } catch (e) {
    return NextResponse.json({ error: (e as Error).message }, { status: 500 });
  }
}
