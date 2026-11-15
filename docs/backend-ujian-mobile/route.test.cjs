// Isolated route contract tests; no production database, credentials, or network.
const {readFileSync}=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const backend=process.env.MARKAZ_BACKEND_DIR || require('node:path').resolve(__dirname,'../../../ijazah-sample');
const ts=require(require.resolve('typescript',{paths:[backend]}));
const code=ts.transpileModule(readFileSync(__dirname+'/route.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText;
let snapshot=null,writes=[],graded=0,user='owner';
let session;
function reset(){snapshot=null;writes=[];graded=0;user='owner';session={id:'s',status:'MENGERJAKAN',tambahanMenit:0,waktuMulai:new Date(),riwayat:{santriId:'owner'},paket:{sesiGlobal:{waktuMulai:new Date(),durasiMenit:60},soalPaketList:[{soalId:'q',soal:{opsiList:[{id:'a'}]}}]}};}
const db={
 sesiUjianSantri:{findUnique:async()=>structuredClone(session)},
 jawabanUjianSantri:{upsert:async(v)=>{writes.push(v);return v;}},
 $queryRaw:async(strings,...values)=>{
  const sql=strings.join('?');
  if(sql.includes('INSERT INTO')){snapshot={sesiId:values[0],ownerId:values[1],clientId:values[2],revision:values[3],payload:JSON.parse(values[4]),sealed:values[5],needsReview:values[6],finalized:false};return [structuredClone(snapshot)];}
  if(sql.includes('SELECT "payload" =')){return [{same:require('node:util').isDeepStrictEqual(snapshot.payload,JSON.parse(values[0]))}];}
  if(sql.includes('SELECT *'))return snapshot?[structuredClone(snapshot)]:[];
  return [];
 },
 $executeRaw:async()=>{snapshot.finalized=true;return 1;},
 $transaction:async(fn)=>{const old=structuredClone(snapshot),len=writes.length;try{return await fn(db);}catch(e){snapshot=old;writes.length=len;throw e;}}
};
const exported={};
vm.runInNewContext(code,{exports:exported,require:(name)=>{
 if(name==='next/server')return {NextResponse:{json:(data,opts)=>({data,status:opts?.status??200})}};
 if(name==='@prisma/client')return {Prisma:{DbNull:null}};
 if(name==='@/lib/prisma')return {__esModule:true,default:db};
 if(name==='@/lib/santri-auth')return {getSantriSession:async()=>user?{santriId:user}:null};
 if(name==='@/lib/exam-submit')return {submitSesiUjianSantri:async()=>{graded++;session.status='SELESAI';}};
 throw Error(name);
},Date,JSON,Map,Set,Error,Object,Number,Array});
function send(revision,answer='ب',reason=null,clientId='device'){
 return exported.POST({text:async()=>JSON.stringify({sesiId:'s',clientId,revision,answers:{q:{jawabanTeks:answer}},reason})});
}
(async()=>{
 reset(); assert.equal((await send(1)).status,200);assert.equal(writes.length,1);
 assert.equal((await send(1)).status,200);assert.equal(writes.length,1,'retry must not write twice');
 assert.equal((await send(1,'different')).status,409);
 assert.equal((await send(2,'x',null,'other')).status,409);
 user='other';assert.equal((await send(2)).status,403);user='owner';
 assert.equal((await send(2,'بِ','MANUAL')).data.finalized,true);assert.equal(graded,1);
 assert.equal((await send(2,'بِ','MANUAL')).data.finalized,true);assert.equal(graded,1);
 assert.equal((await send(3,'late edit','MANUAL')).status,409);
 reset();session.paket.sesiGlobal.waktuMulai=new Date(Date.now()-7200000);
 let r=await send(1,'offline');assert.equal(r.data.expired,true);assert.equal(r.data.finalized,false);assert.equal(writes.length,0);
 r=await send(2,'offline','TIME_UP');assert.equal(r.data.finalized,true);assert.equal(r.data.needsReview,true);assert.equal(snapshot.payload.answers.q.jawabanTeks,'offline');assert.equal(writes.length,0);
 user=null;assert.equal((await send(3)).status,401);
 console.log('PASS: authenticated ownership, device binding, stale/repeated revisions, sealed immutability, offline archive, retry-safe finalization');
})().catch(e=>{console.error(e);process.exitCode=1;});
