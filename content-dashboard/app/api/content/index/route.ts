import { NextResponse } from 'next/server';
import { gzipSync } from 'node:zlib';
import { loadRegistryIndex } from '@/lib/content/data';
import { FILES } from '@/lib/content/schema';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * The full field registry for the client-side fuzzy search + nav.
 *
 * The uncompressed payload is ~15 MB, which exceeds the serverless
 * response-size ceiling (~4.5–6 MB) on Vercel. So we gzip it at the function
 * boundary: the function returns a ~3 MB body (well under the cap) and the
 * browser's fetch() decompresses it transparently via Content-Encoding. This is
 * read-only search data, so compression has no correctness surface, and the
 * client needs no change.
 */
export async function GET() {
  const fields = await loadRegistryIndex();
  const json = JSON.stringify({ files: FILES, fields });
  const body = gzipSync(json);
  return new NextResponse(body, {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Content-Encoding': 'gzip',
      'Vary': 'Accept-Encoding',
      'Cache-Control': 'no-store',
    },
  });
}
