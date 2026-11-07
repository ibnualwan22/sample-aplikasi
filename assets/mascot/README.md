# Maskot Markaz Arabiyah

Gambar asli disediakan pemilik aplikasi; sumber PNG disimpan di `docs/mascot-sources/`.
WebP runtime mempertahankan dimensi, transparansi, pose dan arah tulisan Arab sumber.
Konversi kualitas 88 melalui `tools/encode_mascot.c`; total runtime sekitar 780 KB.
Flutter membatasi resolusi decode sesuai ukuran tampil dan hanya memuat pose yang dipakai.

- `poses.webp`: lima pose tambahan. Sapaan menggunakan pose kiri atas melalui ClipPath.
- `unavailable.webp`: membawa papan.
- `empty.webp`: map kosong.
- `help.webp`: tangan terbuka.
- `success.webp`: jempol.
- `docs/mascot-sources/welcome-alternative.png`: alternatif sapaan terpisah.

Tidak ada animasi 3D runtime. Umpan balik sentuh diterapkan pada widget.
