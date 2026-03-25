import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/coming_soon_dialog.dart';
import 'surah_detail_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<dynamic> _surahList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSurahList();
  }

  Future<void> _fetchSurahList() async {
    final list = await ApiService.getSurahList();
    if (mounted) {
      setState(() {
        _surahList = list ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Al-Qur'an Digital"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showComingSoonDialog(context, 'Pencarian Surat'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            )
          : _surahList.isEmpty
              ? const Center(
                  child: Text('Gagal memuat data surat.', style: TextStyle(color: Colors.white)),
                )
              : ListView.builder(
                  itemCount: _surahList.length,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  itemBuilder: (context, index) {
                    final surah = _surahList[index];
                    return _buildSurahCard(context, surah);
                  },
                ),
    );
  }

  Widget _buildSurahCard(BuildContext context, dynamic surah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            surah['number']?.toString() ?? '',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          surah['name_latin'] ?? 'Surat',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                surah['revelation'] ?? '-',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.circle, size: 4, color: Colors.white.withOpacity(0.6)),
              ),
              Text(
                surah['number_of_ayahs'].toString() + ' Ayat',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: Text(
          surah['name'] ?? '',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri', // Jika ada font arab khusus
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(
                surahNumber: surah['number'] ?? 1,
                surahName: surah['name_latin'] ?? 'Surat',
              ),
            ),
          );
        },
      ),
    );
  }
}
