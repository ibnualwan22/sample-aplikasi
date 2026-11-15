import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getSession } from '@/lib/auth';
import { checkPermission } from '@/lib/permission';

// Read-only recovery evidence. Does not accept/regrade late answers automatically.
export async function GET(req: Request) {
  if (!await getSession()) return NextResponse.json({error:'Unauthorized'},{status:401});
  if (!await checkPermission('ujian_usbu')) return NextResponse.json({error:'Forbidden'},{status:403});
  const sesiId = new URL(req.url).searchParams.get('sesiId');
  if (!sesiId) return NextResponse.json({error:'sesiId diperlukan'},{status:400});
  const snapshots = await prisma.$queryRaw`SELECT "sesiId", "revision", "payload", "sealed", "needsReview", "finalized", "updatedAt" FROM "ExamMobileSnapshot" WHERE "sesiId" = ${sesiId}`;
  return NextResponse.json({snapshots});
}
