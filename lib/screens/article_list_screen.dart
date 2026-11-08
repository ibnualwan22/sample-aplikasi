import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../data/articles.dart';
import '../services/api_service.dart';
import '../theme/markaz_theme.dart';
import '../widgets/markaz_components.dart';
import 'article_detail_screen.dart';

/// Daftar artikel markazarabiyah.com — data live dari WP REST API,
/// urut kronologis (terbaru dulu).
class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});
  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  List<dynamic> _articles = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final list = await ApiService.getArticles();
    if (!mounted) return;
    setState(() {
      _articles = list ?? [];
      _loading = false;
      _failed = list == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artikel')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _failed || _articles.isEmpty
                ? MarkazState(
                    title: 'Artikel belum dapat dimuat',
                    message: 'Periksa koneksi lalu coba lagi.',
                    pose: MascotPose.help,
                    actionLabel: 'Coba lagi',
                    onAction: _fetch,
                  )
                : RefreshIndicator(
                    onRefresh: _fetch,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: _articles.length,
                      itemBuilder: (context, i) {
                        final a =
                            _articles[i] as Map<String, dynamic>;
                        final title =
                            plainText(a['title']?['rendered'] ?? '');
                        final excerpt =
                            plainText(a['excerpt']?['rendered'] ?? '');
                        final image = articleImage(a);
                        final rtl = isArabicText(title);
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ArticleDetailScreen(article: a))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (image != null)
                                  CachedNetworkImage(
                                    imageUrl: image,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Container(
                                            height: 180,
                                            color: MarkazColors.tint),
                                    errorWidget: (context, url, error) =>
                                        const SizedBox.shrink(),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Directionality(
                                        textDirection: rtl
                                            ? TextDirection.rtl
                                            : TextDirection.ltr,
                                        child: Text(title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        articleDate(a),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: MarkazColors.muted),
                                      ),
                                      if (excerpt.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(excerpt,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: MarkazColors.muted)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
