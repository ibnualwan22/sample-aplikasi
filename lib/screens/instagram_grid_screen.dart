import '../theme/markaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const kBgDark = MarkazColors.surface;
const kBgCard = MarkazColors.surface;
const kGold = MarkazColors.gold;
const kGoldLight = MarkazColors.ink;
const kTextPri = MarkazColors.ink;
const kTextSec = MarkazColors.muted;

class InstagramGridScreen extends StatefulWidget {
  const InstagramGridScreen({super.key});

  @override
  State<InstagramGridScreen> createState() => _InstagramGridScreenState();
}

class _InstagramGridScreenState extends State<InstagramGridScreen> {
  bool _isLoading = true;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final res = await ApiService.getInstagramPosts();
    if (mounted) {
      if (res != null && res['success'] == true) {
        final all = res['data'] as List<dynamic>? ?? [];
        final subset = all.take(9).toList(); // Mengambil 9 post terbaru saja

        // Auto-Scrape for missing thumbnails
        await Future.wait(subset.map((post) async {
          final tUrl = post['thumbnailUrl'];
          final pUrl = post['url'];
          if ((tUrl == null || tUrl.toString().isEmpty) &&
              pUrl != null &&
              pUrl.toString().isNotEmpty) {
            final extracted =
                await ApiService.extractInstagramThumbnail(pUrl.toString());
            if (extracted != null) {
              post['thumbnailUrl'] = extracted;
            }
          }
        }));

        setState(() {
          _posts = subset;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openPost(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka Instagram')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MarkazColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '9 Postingan Terbaru',
          style: TextStyle(
              color: MarkazColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(
                  child: Text('Belum ada konten Instagram',
                      style: TextStyle(color: kTextSec)))
              : GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _posts.length,
                  itemBuilder: (ctx, i) {
                    final post = _posts[i];
                    final thumb = post['thumbnailUrl']?.toString() ?? '';
                    final url = post['url']?.toString() ?? '';

                    return GestureDetector(
                      onTap: () {
                        if (url.isNotEmpty) _openPost(url);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: kGold.withValues(alpha: 0.2)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: thumb.isEmpty
                            ? Icon(Icons.camera_alt,
                                color: MarkazColors.muted, size: 30)
                            : CachedNetworkImage(
                                imageUrl: thumb,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      color: MarkazColors.ink, strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image,
                                    color: MarkazColors.muted,
                                    size: 30),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
