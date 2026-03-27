import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Tema warna mengikuti HomeScreen
const kBgDark = Color(0xFF0A0A0A);
const kBgCard = Color(0xFF181818);
const kBgCard2 = Color(0xFF202020);
const kGold = Color(0xFFD4AF37);
const kGoldLight = Color(0xFFEDD56A);
const kGoldDim = Color(0xFF3A2E0A);
const kTextPri = Colors.white;
const kTextSec = Color(0xFFAAAAAA);

class HasilTesScreen extends StatefulWidget {
  const HasilTesScreen({super.key});

  @override
  State<HasilTesScreen> createState() => _HasilTesScreenState();
}

class _HasilTesScreenState extends State<HasilTesScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  List<dynamic> _allData = []; // [ { kelas: "1A", santri: [...] }, ... ]
  String _activeDufah = '';

  String _selectedKelas = 'Semua Kelas';
  int _selectedUsbu = 1;

  List<String> _kelasList = ['Semua Kelas'];
  List<Map<String, dynamic>> _usbuList = [{'usbu': 1, 'label': "Usbu' 1"}];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getHasilTes();

      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        final dufah = response['active_dufah'] ?? '';

        final kelasSet = {'Semua Kelas'};
        List<Map<String, dynamic>> dynamicUsbuList = [];

        for (var kelasData in data) {
          kelasSet.add(kelasData['kelas']);
          for (var santri in (kelasData['santri'] as List<dynamic>)) {
            if (dynamicUsbuList.isEmpty) {
              final rataUsbu = santri['rata_rata_per_usbu'] as List<dynamic>? ?? [];
              for (var r in rataUsbu) {
                if (r['usbu'] != null) {
                  dynamicUsbuList.add({
                    'usbu': r['usbu'],
                    'label': r['label'] ?? "Usbu' ${r['usbu']}"
                  });
                }
              }
            }
          }
        }

        if (dynamicUsbuList.isEmpty) {
          dynamicUsbuList = [{'usbu': 1, 'label': "Usbu' 1"}];
        }

        setState(() {
          _allData = data;
          _activeDufah = dufah;
          _kelasList = kelasSet.toList()..sort();
          _usbuList = dynamicUsbuList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response?['message'] ?? 'Gagal mengambil data dari server';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredData() {
    if (_selectedKelas == 'Semua Kelas') {
      return _allData;
    }
    return _allData.where((k) => k['kelas'] == _selectedKelas).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: kBgCard,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hasil Tes Santri', style: TextStyle(color: kGold, fontWeight: FontWeight.bold, fontSize: 18)),
            if (_activeDufah.isNotEmpty)
              Text('Dufah: $_activeDufah', style: const TextStyle(color: kTextSec, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: kGold),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
                        const SizedBox(height: 16),
                        Text(_errorMessage, style: const TextStyle(color: kTextSec), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: kGoldDim),
                          onPressed: _fetchData,
                          child: const Text('Coba Lagi', style: TextStyle(color: kGoldLight)),
                        )
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildFilterSection(),
                    Expanded(
                      child: _buildResultList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kBgCard,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kelas', style: TextStyle(color: kTextSec, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kBgCard2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kGold.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: kBgCard2,
                      value: _selectedKelas,
                      items: _kelasList.map((k) {
                        return DropdownMenuItem(
                          value: k,
                          child: Text(k, style: const TextStyle(color: kTextPri)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedKelas = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Usbu\' (Pekan)', style: TextStyle(color: kTextSec, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kBgCard2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kGold.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      dropdownColor: kBgCard2,
                      value: _selectedUsbu,
                      items: _usbuList.map((u) {
                        return DropdownMenuItem<int>(
                          value: u['usbu'] as int,
                          child: Text(u['label'].toString(), style: const TextStyle(color: kTextPri)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedUsbu = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    final filteredData = _getFilteredData();

    if (filteredData.isEmpty) {
      return const Center(child: Text('Tidak ada data kelas.', style: TextStyle(color: kTextSec)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final kelasData = filteredData[index];
        final namaKelas = kelasData['kelas'];
        final rawSantriList = kelasData['santri'] as List<dynamic>? ?? [];

        // 1. Prepare data and calculate NILAI AKUMULATIF
        List<Map<String, dynamic>> santriDisplayList = [];
        List<String> mapelNames = []; // To collect column names

        for (var santri in rawSantriList) {
          final rataRataList = santri['rata_rata_per_usbu'] as List<dynamic>? ?? [];
          double rataUsbuIni = 0;
          for (var r in rataRataList) {
            if (r['usbu'] == _selectedUsbu) {
              rataUsbuIni = (r['rata_rata_nilai'] as num?)?.toDouble() ?? 0;
            }
          }

          final nilaiPerMapel = santri['nilai_per_mapel'] as List<dynamic>? ?? [];
          Map<String, num> mapelScores = {};
          for (var m in nilaiPerMapel) {
            final namaMapel = m['mapel']?.toString() ?? '-';
            if (!mapelNames.contains(namaMapel)) {
              mapelNames.add(namaMapel);
            }
            num? nilaiMapel;
            if (_selectedUsbu == 1) {
              nilaiMapel = m['nilai_usbu_1'] as num?;
            } else if (_selectedUsbu == 2) {
              nilaiMapel = m['nilai_usbu_2'] as num?;
            } else if (_selectedUsbu == 3) {
              nilaiMapel = m['nilai_nihai'] as num?;
            } else if (_selectedUsbu == 4) {
              nilaiMapel = m['nilai_akhir'] as num?;
            } else {
              nilaiMapel = m['nilai_usbu_$_selectedUsbu'] as num?;
            }
            mapelScores[namaMapel] = nilaiMapel ?? 0;
          }

          santriDisplayList.add({
            'nama': santri['nama'] ?? 'Tanpa Nama',
            'gender': santri['gender'] ?? '-',
            'rata': rataUsbuIni,
            'mapelScores': mapelScores,
          });
        }

        // 2. Sort by rata desc
        santriDisplayList.sort((a, b) => (b['rata'] as double).compareTo(a['rata'] as double));

        // 3. Build DataTable
        return Card(
          color: kBgCard2,
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Kelas $namaKelas',
                  style: const TextStyle(color: kGoldLight, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (santriDisplayList.isEmpty)
                  const Text('Tidak ada santri di kelas ini.', style: TextStyle(color: kTextSec))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.white12,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFD4AF37)),
                        dataRowColor: WidgetStateProperty.resolveWith((states) => kBgDark),
                        headingTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        dataTextStyle: const TextStyle(color: kTextPri, fontSize: 13),
                        columnSpacing: 20,
                        border: TableBorder.all(color: Colors.black26, width: 1),
                        columns: [
                          const DataColumn(label: Text('No')),
                          const DataColumn(label: Text('NAMA PESERTA\nDIDIK')),
                          ...mapelNames.map((m) => DataColumn(label: Center(child: Text(m.toUpperCase())))),
                          const DataColumn(label: Center(child: Text('NILAI\nAKUMULATIF'))),
                          const DataColumn(label: Center(child: Text('PERINGKAT'))),
                          const DataColumn(label: Center(child: Text('GENDER'))),
                        ],
                        rows: List.generate(santriDisplayList.length, (sIndex) {
                          final s = santriDisplayList[sIndex];
                          final mapelScores = s['mapelScores'] as Map<String, num>;
                          // Menghilangkan desimal jika nilai bulat (misal 94.0 -> 94)
                          String formatScore(num val) => val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);
                          return DataRow(
                            cells: [
                              DataCell(Center(child: Text('${sIndex + 1}'))),
                              DataCell(Text(s['nama'])),
                              ...mapelNames.map((m) {
                                final score = mapelScores[m] ?? 0;
                                return DataCell(Center(child: Text(formatScore(score))));
                              }),
                              DataCell(Center(child: Text(formatScore(s['rata'] as double), style: const TextStyle(fontWeight: FontWeight.bold)))),
                              DataCell(Center(child: Text('${sIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: kGoldLight)))),
                              DataCell(Center(child: Text(s['gender'].toString()))),
                            ]
                          );
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
