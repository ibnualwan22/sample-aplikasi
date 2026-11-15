// Tests the real backend helper without a database, network, or AI grading.
// Run with MARKAZ_BACKEND_DIR pointing to the backend checkout if not adjacent.
const { readFileSync } = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const backend = process.env.MARKAZ_BACKEND_DIR || path.resolve(__dirname, '../../../ijazah-sample');
const ts = require(require.resolve('typescript', { paths: [backend] }));
const code = ts.transpileModule(readFileSync(path.join(backend, 'src/lib/exam-submit.ts'), 'utf8'), {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, esModuleInterop: true },
}).outputText;
let state, failAnswerWrite, writes, lockHeld;
function reset() {
  failAnswerWrite = false; writes = []; lockHeld = false;
  state = {
    id: 's', status: 'MENGERJAKAN', riwayatId: 'r', riwayat: { jumlah_kolom_usbu: 1 },
    paket: { program: { nama_indo: 'Arabiyah' }, sesiGlobal: { usbuKe: 1 }, soalPaketList: [{ soal: {
      id: 'q', mapelId: 'm', mapel: { jumlah_tes: 1 }, tipeSoal: 'ESSAY_SINGKAT',
      bobot: 10, kunciJawaban: 'answer', opsiList: [],
    } }] },
    jawabanList: [{ id: 'j', soalId: 'q', jawabanTeks: 'answer', nilaiManual: null }],
  };
}
function write(kind, value) {
  assert.equal(lockHeld, true, 'all writes must hold the session row lock');
  writes.push({ kind, value });
}
const tx = {
  $queryRaw: async (strings) => { assert.match(strings.join(''), /FOR UPDATE/); lockHeld = true; return [{ id: 's' }]; },
  sesiUjianSantri: {
    findUnique: async () => { assert.equal(lockHeld, true); return structuredClone(state); },
    update: async ({ data }) => { write('session', data); Object.assign(state, data); return structuredClone(state); },
  },
  nilai: { findMany: async () => [], create: async (v) => { write('grade', v); return v; } },
  jawabanUjianSantri: { update: async (v) => {
    if (failAnswerWrite) throw Error('write failed'); write('answer', v); return v;
  } },
};
// Global access throws: the helper must use the SAME transaction connection.
const db = new Proxy({
  $transaction: async (fn) => {
    const before = structuredClone(state), beforeWrites = structuredClone(writes);
    try { return await fn(tx); }
    catch (error) { state = before; writes = beforeWrites; throw error; }
    finally { lockHeld = false; }
  },
}, { get: (target, prop) => {
  if (prop in target) return target[prop];
  throw Error('Unexpected access outside transaction: ' + String(prop));
} });
const exported = {};
vm.runInNewContext(code, { exports: exported, require: (name) => {
  if (name === '@/lib/prisma') return { __esModule: true, default: db };
  if (name === '@/lib/arabic-utils') return { normalizeAnswerText: (v) => v.trim() };
  if (name === '@/lib/grade-calculator') return {};
  throw Error(name);
}, console, setTimeout });
(async () => {
  reset();
  let result = await exported.submitSesiUjianSantri('s', 'MANUAL');
  assert.equal(result.status, 'SELESAI'); assert.equal(result.nilaiTotal, 100);
  assert.equal(writes.length, 3);
  await exported.submitSesiUjianSantri('s', 'MANUAL');
  assert.equal(writes.length, 3, 'retry cannot grade twice');
  reset(); failAnswerWrite = true;
  await assert.rejects(exported.submitSesiUjianSantri('s', 'MANUAL'), /write failed/);
  assert.equal(state.status, 'MENGERJAKAN'); assert.equal(writes.length, 0);
  failAnswerWrite = false;
  result = await exported.submitSesiUjianSantri('s', 'LOCK_LOST');
  assert.equal(result.status, 'AUTO_SUBMIT'); assert.equal(result.tabCloseCount, undefined);
  console.log('PASS: same transaction connection, grading, retry idempotency, rollback, non-punitive lock loss');
})().catch((error) => { console.error(error); process.exitCode = 1; });
