import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SigmaLaporanScreen extends StatefulWidget {
  const SigmaLaporanScreen({super.key});

  @override
  State<SigmaLaporanScreen> createState() => _SigmaLaporanScreenState();
}

class _SigmaLaporanScreenState extends State<SigmaLaporanScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _laporanData;
  String? _errorMsg;

  Future<void> _cariLaporan() async {
    final nama = _controller.text.trim();
    if (nama.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _laporanData = null;
    });

    final data = await ApiService.getLaporanSigma(nama);
    if (mounted) {
      if (data != null && data['success'] == true && data['data'] != null) {
        setState(() {
          _isLoading = false;
          _laporanData = data;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = data?['message'] ?? 'Data santri tidak ditemukan atau koneksi gagal.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portal Laporan SIGMA')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari Nama Santri (Misal: Ahmad)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _cariLaporan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cari', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37))))
                : _errorMsg != null 
                  ? Center(child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent)))
                  : _laporanData != null
                    ? _buildLaporanView()
                    : const Center(child: Text('Masukkan Nama Santri (Coba: Ahmad) untuk memuat laporan SIGMA.', style: TextStyle(color: Colors.white54))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanView() {
    final dynamic rawData = _laporanData!['data'];
    List<dynamic> listData;
    if (rawData is List) {
      listData = List.from(rawData);
    } else if (rawData is Map) {
      listData = [rawData];
    } else {
      listData = [];
    }
    
    // Urutkan List Data Berdasarkan Dufah (Descending / Paling Baru di atas)
    listData.sort((a, b) {
      final da = (a?['dufah'] ?? '').toString();
      final db = (b?['dufah'] ?? '').toString();
      return db.compareTo(da);
    });
    
    final activeDufah = _laporanData!['active_dufah'] as String?;

    if (listData.isEmpty) {
      return const Center(child: Text('Data riwayat kosong.', style: TextStyle(color: Colors.white54)));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: listData.map((laporan) {
          final santri = laporan['santri'] as Map<String, dynamic>? ?? {};
          final akademik = laporan['akademik'] as Map<String, dynamic>? ?? {};
          final nilaiMapel = laporan['nilai_per_mapel'] as List<dynamic>? ?? [];
          final rekapAbsen = laporan['rekap_absen_per_usbu'] as List<dynamic>? ?? [];
          final dufah = laporan['dufah'] as String?;
          final isAktif = dufah == activeDufah;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(dufah ?? '-', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                    if (isAktif) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD4AF37))),
                        child: const Text('AKTIF', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ]
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF2A2A2A),
                        child: Icon(Icons.person, color: Color(0xFFD4AF37), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(santri['nama'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('ID: ' + (santri['id']?.toString() ?? ''), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14)),
                            const SizedBox(height: 4),
                            Text((akademik['program']?.toString() ?? '') + ' • ' + (akademik['kelas']?.toString() ?? ''), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (nilaiMapel.isNotEmpty) ...[
                  const Text('Nilai Per Mata Pelajaran', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...nilaiMapel.map((mapel) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(mapel['mapel'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Text(mapel['nilai_akhir']?.toString() ?? '-', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('U1: ${mapel['nilai_usbu_1'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('U2: ${mapel['nilai_usbu_2'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('Nihai: ${mapel['nilai_nihai'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                if (rekapAbsen.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Rekap Absensi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...rekapAbsen.map((rekap) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
                            child: Text('U-${rekap['usbu'] ?? '-'}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(children: [const Text('Hadir', style: TextStyle(color: Colors.green, fontSize: 10)), Text('${rekap['total_hadir'] ?? 0}', style: const TextStyle(color: Colors.white))]),
                                Column(children: [const Text('Izin', style: TextStyle(color: Colors.blue, fontSize: 10)), Text('${rekap['total_izin'] ?? 0}', style: const TextStyle(color: Colors.white))]),
                                Column(children: [const Text('Sakit', style: TextStyle(color: Colors.orange, fontSize: 10)), Text('${rekap['total_sakit'] ?? 0}', style: const TextStyle(color: Colors.white))]),
                                Column(children: [const Text('Alpha', style: TextStyle(color: Colors.red, fontSize: 10)), Text('${rekap['total_alpha'] ?? 0}', style: const TextStyle(color: Colors.white))]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
