import { NextRequest, NextResponse } from 'next/server';
import { loadChangesFeed } from '@/lib/content/data';

export const runtime = 'nodejs';

export async function GET(req: NextRequest) {
  const sp = req.nextUrl.searchParams;
  const feed = await loadChangesFeed({
    author: sp.get('author') ?? undefined,
    file: sp.get('file') ?? undefined,
    limit: Number(sp.get('limit') ?? 200),
  });
  return NextResponse.json({ changes: feed });
}
