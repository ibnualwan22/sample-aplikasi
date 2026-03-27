import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<dynamic>? _hasilTesData;
  String? _errorMsg;

  int _selectedUsbu = 4; // Default usbu 4
  List<Map<String, dynamic>> _usbuList = [
    {'usbu': 1, 'label': "Usbu' 1"},
    {'usbu': 2, 'label': "Usbu' 2"},
    {'usbu': 3, 'label': "Usbu' 3 (Nihai)"},
    {'usbu': 4, 'label': "Gabungan Semua Usbu'"},
  ];

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
        try {
          // Ambil hasil tes secara paralel/setelahnya untuk perhitungan rank pada active dufah
          final tesRes = await ApiService.getHasilTes();
          if (tesRes != null && tesRes['success'] == true) {
             _hasilTesData = tesRes['data'] as List<dynamic>?;
          }
        } catch (_) {}

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

  int _getPeringkatSantri(String santriId, int selectedUsbu, String targetKelas) {
    if (_hasilTesData == null) return 0;
    
    final kelasDataOption = _hasilTesData!.where((k) => k['kelas'] == targetKelas).toList();
    if (kelasDataOption.isEmpty) return 0;
    
    final kelasData = kelasDataOption.first;
    List<dynamic> santriList = kelasData['santri'] ?? [];
    List<Map<String, dynamic>> computedList = [];

    for (var s in santriList) {
       final rataRataList = s['rata_rata_per_usbu'] as List<dynamic>? ?? [];
       double rata = 0;
       for (var r in rataRataList) {
         if (r['usbu'] == selectedUsbu) {
           rata = (r['rata_rata_nilai'] as num?)?.toDouble() ?? 0;
         }
       }
       computedList.add({'id': s['id_santri'], 'rata': rata});
    }

    computedList.sort((a,b) => (b['rata'] as double).compareTo(a['rata'] as double));
    int rank = computedList.indexWhere((s) => s['id'] == santriId) + 1;
    return rank;
  }

  double _getAkumulatifLokal(List<dynamic> nilaiMapel, int selectedUsbu) {
    double sum = 0;
    int count = 0;
    for (var m in nilaiMapel) {
      final mapelName = m['mapel']?.toString().toLowerCase() ?? '';
      if (mapelName != 'presensi') {
        num? score;
        if (selectedUsbu == 1) score = m['nilai_usbu_1'] as num?;
        else if (selectedUsbu == 2) score = m['nilai_usbu_2'] as num?;
        else if (selectedUsbu == 3) score = m['nilai_nihai'] as num?;
        else if (selectedUsbu == 4) score = m['nilai_akhir'] as num?;
        else score = m['nilai_usbu_$selectedUsbu'] as num?;
        
        if (score != null) {
          sum += score;
          count++;
        }
      }
    }
    return count > 0 ? (sum / count) : 0.0;
  }

  String _getGenderSantri(String santriId, String fallback) {
    if (_hasilTesData == null) return fallback;
    for (var k in _hasilTesData!) {
      final santriList = k['santri'] as List<dynamic>? ?? [];
      for (var s in santriList) {
        if (s['id_santri'] == santriId || s['id'] == santriId) {
          return s['gender']?.toString() ?? fallback;
        }
      }
    }
    return fallback;
  }

  String _formatScore(num val) => val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(backgroundColor: const Color(0xFF181818), title: const Text('Portal Laporan SIGMA')),
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
    
    // Urutkan berdasarkan Dufah descending
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
          final historiAbsen = laporan['histori_absen_terbaru'] as Map<String, dynamic>? ?? {};
          final kelasAbsen = historiAbsen['kelas'] as List<dynamic>? ?? [];
          
          final dufah = laporan['dufah'] as String?;
          final isAktif = dufah == activeDufah;
          
          final targetKelas = akademik['kelas']?.toString() ?? '-';
          final rankLokal = isAktif ? _getPeringkatSantri(santri['id']?.toString() ?? '', _selectedUsbu, targetKelas) : 0;
          final akumulatifLokal = _getAkumulatifLokal(nilaiMapel, _selectedUsbu);
          final rawGender = santri['gender']?.toString();
          final genderSantri = (rawGender != null && rawGender != 'null') 
              ? rawGender 
              : _getGenderSantri(santri['id']?.toString() ?? '', '-');

          return Container(
            margin: const EdgeInsets.only(bottom: 32),
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
                            Text('ID: ${(santri['id'] ?? '')}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${akademik['program'] ?? ''} • $targetKelas', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (nilaiMapel.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tabel Evaluasi (Individual)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: const Color(0xFF202020), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3))),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedUsbu,
                            dropdownColor: const Color(0xFF202020),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD4AF37), size: 16),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            items: _usbuList.map((u) {
                              return DropdownMenuItem<int>(
                                value: u['usbu'] as int,
                                child: Text(u['label'].toString()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedUsbu = val);
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.white12),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFD4AF37)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFF0A0A0A)),
                        headingTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
                        columnSpacing: 20,
                        border: TableBorder.all(color: Colors.black26, width: 1),
                        columns: [
                          const DataColumn(label: Text('No')),
                          const DataColumn(label: Text('NAMA PESERTA\nDIDIK')),
                          ...nilaiMapel.map((m) => DataColumn(label: Center(child: Text((m['mapel']?.toString() ?? '-').toUpperCase())))),
                          const DataColumn(label: Center(child: Text('NILAI\nAKUMULATIF'))),
                          const DataColumn(label: Center(child: Text('PERINGKAT'))),
                          const DataColumn(label: Center(child: Text('GENDER'))),
                        ],
                        rows: [
                          DataRow(cells: [
                            const DataCell(Center(child: Text('1'))),
                            DataCell(Text(santri['nama'] ?? '-')),
                            ...nilaiMapel.map((m) {
                              num? score;
                              if (_selectedUsbu == 1) score = m['nilai_usbu_1'] as num?;
                              else if (_selectedUsbu == 2) score = m['nilai_usbu_2'] as num?;
                              else if (_selectedUsbu == 3) score = m['nilai_nihai'] as num?;
                              else if (_selectedUsbu == 4) score = m['nilai_akhir'] as num?;
                              else score = m['nilai_usbu_$_selectedUsbu'] as num?;
                              
                              return DataCell(Center(child: Text(_formatScore(score ?? 0))));
                            }),
                            DataCell(Center(child: Text(_formatScore(akumulatifLokal), style: const TextStyle(fontWeight: FontWeight.bold)))),
                            DataCell(Center(child: Text(isAktif && rankLokal > 0 ? rankLokal.toString() : '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEDD56A))))),
                            DataCell(Center(child: Text(genderSantri))),
                          ])
                        ],
                      ),
                    ),
                  ),
                ],
                if (kelasAbsen.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Histori Absen Harian (Terbaru)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.white12),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFD4AF37)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFF0A0A0A)),
                        headingTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
                        columnSpacing: 20,
                        border: TableBorder.all(color: Colors.black26, width: 1),
                        columns: const [
                          DataColumn(label: Text('TANGGAL')),
                          DataColumn(label: Text('SESI')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('KETERANGAN')),
                        ],
                        rows: kelasAbsen.map((absen) {
                          final tgl = absen['tanggal'] != null 
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(absen['tanggal']))
                              : '-';
                          final status = absen['status']?.toString() ?? '-';
                          final color = status == 'HADIR' ? Colors.green : status == 'SAKIT' ? Colors.orange : status == 'IZIN' ? Colors.blue : Colors.red;
                          
                          return DataRow(cells: [
                            DataCell(Text(tgl)),
                            DataCell(Text((absen['sesi']?.toString() ?? '-').replaceAll('SESI_', ''))),
                            DataCell(Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                            DataCell(Text(absen['keterangan']?.toString() ?? '-')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
