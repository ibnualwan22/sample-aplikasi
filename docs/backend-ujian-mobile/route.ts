import { NextResponse } from "next/server";
import { Prisma } from "@prisma/client";
import prisma from "@/lib/prisma";
import { getSantriSession } from "@/lib/santri-auth";
import { submitSesiUjianSantri } from "@/lib/exam-submit";

type Snapshot = { sesiId: string; clientId: string; revision: number; payload: any; sealed: boolean; needsReview: boolean; finalized: boolean };
const reasons = new Set(["MANUAL", "TIME_UP", "TAB_CLOSE", "LOCK_LOST", "SERVER_CLOSED"]);
export async function GET() {
  if (!await getSantriSession()) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  // This also verifies migration readiness before the app starts an exam.
  try {
    await prisma.$queryRaw`SELECT "sesiId" FROM "ExamMobileSnapshot" LIMIT 0`;
    return NextResponse.json({ protocol: 1, lockRequired: true });
  } catch { return NextResponse.json({ error: "Protokol ujian mobile belum diaktifkan oleh administrator." }, { status: 503 }); }
}
export async function POST(req: Request) {
  const auth = await getSantriSession();
  if (!auth) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  try {
    const text = await req.text();
    if (text.length > 2_000_000) return NextResponse.json({ error: "Ukuran jawaban melampaui batas." }, { status: 413 });
    const body = JSON.parse(text);
    const { sesiId, clientId, revision, answers, reason } = body;
    if (typeof sesiId !== "string" || typeof clientId !== "string" || clientId.length > 100 || !clientId ||
      !Number.isSafeInteger(revision) || revision < 0 || !answers || typeof answers !== "object" || Array.isArray(answers) ||
      (reason != null && !reasons.has(reason))) {
      return NextResponse.json({ error: "Snapshot tidak valid." }, { status: 400 });
    }
    const receipt = await prisma.$transaction(async tx => {
      // Serialize mobile writes and finalization decisions for this exam session.
      await tx.$queryRaw`SELECT "id" FROM "SesiUjianSantri" WHERE "id" = ${sesiId} FOR UPDATE`;
      const sesi = await tx.sesiUjianSantri.findUnique({ where: { id: sesiId }, include: {
        riwayat: true, paket: { include: { sesiGlobal: true, soalPaketList: { include: { soal: { include: { opsiList: true } } } } } }
      } });
      if (!sesi || sesi.riwayat.santriId !== auth.santriId) throw new Error("FORBIDDEN");
      const existing = (await tx.$queryRaw<Snapshot[]>`SELECT * FROM "ExamMobileSnapshot" WHERE "sesiId" = ${sesiId}`)[0];
      if (existing && existing.clientId !== clientId) throw new Error("DEVICE_CONFLICT");
      if (existing && revision <= existing.revision) {
        if (revision === existing.revision && JSON.stringify(existing.payload) !== JSON.stringify(JSON.parse(JSON.stringify({answers,reason:reason??null})))) {
          // Compare JSONB structurally: object property order is not significant.
          const same = await tx.$queryRaw<{same:boolean}[]>`SELECT "payload" = ${JSON.stringify({answers,reason:reason??null})}::jsonb AS same FROM "ExamMobileSnapshot" WHERE "sesiId" = ${sesiId}`;
          if (!same[0]?.same) throw new Error("REVISION_CONFLICT");
        }
        return existing;
      }
      if (existing?.sealed) throw new Error("SEALED");
      const questions = new Map(sesi.paket.soalPaketList.map(p => [p.soalId, p.soal]));
      for (const [id, raw] of Object.entries(answers)) {
        const question = questions.get(id); const value = raw as any;
        if (!question || !value || typeof value !== "object" || Array.isArray(value)) throw new Error("INVALID_ANSWER");
        if (value.opsiId != null && !question.opsiList.some(o => o.id === value.opsiId)) throw new Error("INVALID_ANSWER");
        if (value.jawabanTeks != null && (typeof value.jawabanTeks !== 'string' || value.jawabanTeks.length > 100000)) throw new Error("INVALID_ANSWER");
        if (value.rpiId != null && typeof value.rpiId !== 'string') throw new Error("INVALID_ANSWER");
      }
      const global = sesi.paket.sesiGlobal;
      const start = global.waktuMulai ?? sesi.waktuMulai;
      const deadline = start.getTime() + (global.durasiMenit + sesi.tambahanMenit) * 60000;
      const late = existing?.needsReview === true || sesi.status !== "MENGERJAKAN" || Date.now() > deadline;
      const sealed = reason != null;
      // Late data is safely archived, never silently overwrites already graded answers.
      if (!late) for (const [soalId, raw] of Object.entries(answers)) {
        const v = raw as any;
        const data = { opsiId: v.opsiId ?? null, rpiId: v.rpiId ?? null,
          jawabanTeks: v.jawabanTeks ?? null, jawabanData: v.jawabanData == null ? Prisma.DbNull : v.jawabanData };
        await tx.jawabanUjianSantri.upsert({ where: { sesiId_soalId: { sesiId, soalId } },
          create: { sesiId, soalId, ...data }, update: data });
      }
      const payload = JSON.stringify({ answers, reason: reason ?? null });
      const result = await tx.$queryRaw<Snapshot[]>`
        INSERT INTO "ExamMobileSnapshot" ("sesiId","ownerId","clientId","revision","payload","sealed","needsReview")
        VALUES (${sesiId},${auth.santriId},${clientId},${revision},${payload}::jsonb,${sealed},${late})
        ON CONFLICT ("sesiId") DO UPDATE SET "revision"=EXCLUDED."revision", "payload"=EXCLUDED."payload",
          "sealed"=EXCLUDED."sealed", "needsReview"=EXCLUDED."needsReview", "updatedAt"=CURRENT_TIMESTAMP
        RETURNING *`;
      return result[0];
    }, { timeout: 30000 });
    if (receipt.sealed && !receipt.finalized) {
      // Retry-safe finalization. Snapshot already committed even if grading fails.
      const state = await prisma.sesiUjianSantri.findUnique({where:{id:sesiId},select:{status:true}});
      if (state?.status === 'MENGERJAKAN') {
        try { await submitSesiUjianSantri(sesiId, receipt.needsReview ? 'TIME_UP' : (receipt.payload.reason ?? 'TIME_UP')); }
        catch (error) {
          const after = await prisma.sesiUjianSantri.findUnique({where:{id:sesiId},select:{status:true}});
          if (after?.status === 'MENGERJAKAN') throw error;
        }
      }
      await prisma.$executeRaw`UPDATE "ExamMobileSnapshot" SET "finalized"=true WHERE "sesiId"=${sesiId}`;
      receipt.finalized = true;
    }
    return NextResponse.json({ success:true, revision:receipt.revision, sealed:receipt.sealed, expired:receipt.needsReview,
      finalized:receipt.finalized, needsReview:receipt.needsReview });
  } catch (error) {
    const code = error instanceof Error ? error.message : '';
    const messages: Record<string,string> = {
      FORBIDDEN:'Sesi ujian tidak ditemukan.', DEVICE_CONFLICT:'Sesi terikat pada perangkat lain. Hubungi pengawas.',
      REVISION_CONFLICT:'Revisi jawaban bertentangan. Draf lokal tetap disimpan; hubungi pengawas.',
      SEALED:'Jawaban server sudah dikunci. Draf lokal tetap disimpan; hubungi pengawas.',
      INVALID_ANSWER:'Data jawaban tidak sesuai paket ujian.',
    };
    return NextResponse.json({error:messages[code]??'Sinkronisasi belum selesai. Draf lokal tetap disimpan, silakan coba lagi.'},
      {status:code==='FORBIDDEN'?403:messages[code]?409:503});
  }
}
