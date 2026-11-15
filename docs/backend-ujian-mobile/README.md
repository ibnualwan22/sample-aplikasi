# Aktivasi ujian mobile

Kode sudah diterapkan pada checkout backend `/home/ibnualwan/ijazah-sample`. `backend.patch` adalah salinan perubahan untuk review/pemindahan, bukan perintah yang perlu dijalankan lagi pada checkout tersebut. Tidak ada migrasi atau deploy produksi yang dijalankan.

## Backend

1. Review perubahan dan backup basis data sesuai prosedur operasional.
2. Terapkan migrasi `20261115000100_exam_mobile_snapshot` melalui alur migrasi backend, generate Prisma client, lalu deploy endpoint dan perubahan finalisasi bersama-sama. Rute web `jawab` membutuhkan tabel baru; jangan deploy kode tanpa migrasi.
3. Endpoint `GET /api/santri/ujian/mobile-sync` memeriksa versi protokol dan kesiapan tabel. Aplikasi menolak mulai ujian sebelum endpoint ini siap.
4. Endpoint POST menyimpan snapshot lengkap/revisi, mengikat satu client pada sesi, memeriksa kepemilikan dan soal/opsi, menolak mutasi setelah tersegel serta mengonfirmasi setelah commit.
5. Jawaban yang diterima setelah tenggat/status selesai tetap disimpan di tabel snapshot dengan `needsReview=true`. Nilai/jawaban penilaian yang sudah final tidak ditimpa otomatis. Pengawas dengan izin `ujian_usbu` dapat membaca bukti melalui `GET /api/admin/ujian-usbu/mobile-sync?sesiId=...` dan mengikuti prosedur review nilai yang ada. Dashboard review baru dan penerimaan otomatis jawaban terlambat bukan bagian perubahan ini.
6. Jalankan uji integrasi staging PostgreSQL, termasuk balapan request, retry setelah commit tapi respons hilang, tenggat, sesi ditutup pengawas, dan logout/login. Tes kontrak mock tidak menggantikan uji basis data nyata.

Finalisasi, snapshot mobile, dan penulisan jawaban web menggunakan penguncian baris sesi yang sama. Semua perubahan nilai/status dalam finalisasi memakai satu transaksi dan satu koneksi. Kegagalan menulis membatalkan seluruh finalisasi; retry tidak menghitung nilai dua kali. Penilaian AI opsional yang sudah ada baru dipicu setelah commit.

Tes tanpa akses basis data: `node docs/backend-ujian-mobile/route.test.cjs` dan `node docs/backend-ujian-mobile/finalization.test.cjs` dari root aplikasi Flutter. Keduanya memakai TypeScript dari checkout backend di sebelah folder aplikasi; set `MARKAZ_BACKEND_DIR` jika lokasinya berbeda.

Snapshot terikat akun dan perangkat; pemindahan perangkat selama ujian memerlukan keputusan pengawas. Jangan menghapus snapshot untuk mengatasi konflik tanpa menyelamatkan buktinya. `clientId` adalah identitas antrean, bukan attestation perangkat. Waktu perangkat tidak dipercaya untuk mengesahkan jawaban terlambat.

## Android

Integrator Kotlin mengaktifkan `startLockTask()` hanya bila DPC telah mengizinkan application ID, lalu memeriksa `LOCK_TASK_MODE_LOCKED`. Tidak menggunakan screen pinning sebagai pengganti. DPC/MDM institusi perlu mengizinkan hanya aplikasi ujian, mengatur `setLockTaskFeatures` sesuai kebijakan, serta memblokir overlay dengan `DISALLOW_CREATE_WINDOWS`. Aplikasi ini tidak diam-diam mengangkat dirinya menjadi Device Owner.

Uji pada perangkat terkelola: Home/Recents, gesture, notifikasi, overlay, kunci layar, panggilan, penghentian proses, dan pelepasan mode setelah jawaban tersegel. Pengaturan ini tidak otomatis tersedia pada HP pribadi yang hanya memasang APK.

## iOS / iPadOS

Integrator Swift memakai `AEAssessmentSession`, menunggu callback berhasil sebelum membuka soal, menangani interupsi, dan menutup sesi melalui callback. Dukungan minimum AAC: iOS 13.4. Keyboard pihak ketiga ditolak selama sesi assessment.

Ajukan entitlement `com.apple.developer.automatic-assessment-configuration` ke Apple. Setelah disetujui, gabungkan isi `ios/Runner/Assessment.entitlements.example` ke entitlements aplikasi, set `CODE_SIGN_ENTITLEMENTS` pada konfigurasi build terkait, dan gunakan provisioning profile yang memuat entitlement tersebut. File contoh sengaja tidak diaktifkan pada signing biasa yang belum mendapat persetujuan; runtime akan menolak mode ujian.

Build/test iOS membutuhkan Mac/Xcode dan perangkat Apple. Uji akhir harus memastikan sistem benar-benar terkunci, interupsi menyembunyikan soal, serta mode dilepas sesudah selesai. APK Android tidak memverifikasi perilaku iOS.

## Batas verifikasi

- Tes Flutter dijalankan pada salinan `/tmp/markaz-exam-tests` dengan kode lib/test yang sama. Hanya deklarasi aset Tentang `assets/images/aksara-ksu-batch10.jpg` yang hilang dari repo dikecualikan dari pubspec salinan.
- Versi dependency deklaratif tidak diubah; SDK lokal mengatur dependency tes yang kompatibel. Lockfile repo dipertahankan.
- Screenshot memakai data contoh dan bridge penguncian tiruan, bukan bukti perangkat sudah terkunci secara fisik.

Hasil lengkap dan preview: [verifikasi ujian](../theme-verification/ujian-mobile.md).

## Referensi platform

- [Android Lock Task](https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode): allowlist DPC, status penguncian, dan pengaturan fitur sistem.
- [Apple Assessment Mode](https://developer.apple.com/documentation/automaticassessmentconfiguration/preparing-an-educational-assessment-app-for-distribution): entitlement, provisioning, dan pembatasan keyboard pihak ketiga.
- [Delegate sesi Apple](https://developer.apple.com/documentation/automaticassessmentconfiguration/aeassessmentsessiondelegate): menunggu callback mulai/selesai dan menangani interupsi.
