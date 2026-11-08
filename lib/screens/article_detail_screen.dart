import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/articles.dart';
import '../theme/markaz_theme.dart';

/// Halaman baca satu artikel (isi lengkap dari WP REST API).
/// Artikel berbahasa Arab ditampilkan rata kanan (RTL).
class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final title = plainText(article['title']?['rendered'] ?? '');
    final content = article['content']?['rendered'] as String? ?? '';
    final image = articleImage(article);
    final plainHead = plainText(content);
    final rtl = isArabicText(title) ||
        isArabicText(plainHead.substring(
            0, plainHead.length < 200 ? plainHead.length : 200));
    return Scaffold(
      appBar: AppBar(title: const Text('Artikel')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                          height: 200, color: MarkazColors.tint),
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(articleDate(article),
                    style: const TextStyle(
                        fontSize: 12, color: MarkazColors.muted)),
                const SizedBox(height: 16),
                Html(
                  data: content,
                  style: {
                    'body': Style(
                        color: MarkazColors.ink,
                        fontFamily: 'Roboto',
                        fontFamilyFallback: ['Amiri'],
                        fontSize: FontSize(16)),
                    'a': Style(color: MarkazColors.ink),
                  },
                  onLinkTap: (url, _, __) async {
                    if (url != null) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
