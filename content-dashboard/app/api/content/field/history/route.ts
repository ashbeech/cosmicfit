import { NextRequest, NextResponse } from 'next/server';
import { loadFieldHistory } from '@/lib/content/data';

export const runtime = 'nodejs';

export async function GET(req: NextRequest) {
  const fieldId = req.nextUrl.searchParams.get('fieldId');
  if (!fieldId) return NextResponse.json({ error: 'missing_fieldId' }, { status: 400 });
  const history = await loadFieldHistory(fieldId);
  return NextResponse.json({ history });
}
