import { NextResponse } from 'next/server';
import { loadRegistryIndex } from '@/lib/content/data';
import { FILES } from '@/lib/content/schema';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

/**
 * The full field registry for the client-side fuzzy search + nav. Shipped once
 * (a few MB, gzipped by Next) — search then runs entirely in the browser with
 * no per-keystroke round-trip.
 */
export async function GET() {
  const fields = await loadRegistryIndex();
  return NextResponse.json({ files: FILES, fields });
}
