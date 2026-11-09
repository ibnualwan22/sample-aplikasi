import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../siakad/api.dart';

/// Channel notifikasi pengumuman (Android): importance HIGH supaya tampil
/// sebagai heads-up di layar, seperti WhatsApp. Dibuat sekali (idempotent);
/// Android tidak mengubah importance maupun suara channel yang sudah ada,
/// jadi id ini harus baru (bukan channel bawaan FCM, bukan channel lama).
/// Channel baru 'pengumuman_v3' (batch 1.0.6+8) memakai suara khusus
/// res/raw/three_bright_notes.mp3; channel 'pengumuman_v2' (1.0.6+7)
/// ditinggalkan karena terlanjur dibuat TANPA suara di HP (file suara
/// dibuang shrinker R8) dan suara channel Android tak bisa diubah
/// setelah dibuat. keep.xml menjaga file suara tetap ada di APK.
const String pengumumanChannelId = 'pengumuman_v3';
const String pengumumanChannelName = 'Pengumuman';
const String pengumumanChannelDescription = 'Pengumuman dari Siakad';

/// Suara channel pengumuman (nama resource di res/raw, tanpa ekstensi).
const String pengumumanSoundName = 'three_bright_notes';

/// Isi notifikasi lokal untuk satu pengumuman (fungsi murni agar mudah diuji).
class PengumumanNotificationContent {
  const PengumumanNotificationContent({
    required this.title,
    required this.body,
    required this.payload,
  });

  /// Judul notifikasi = pengirim.
  final String title;

  /// Isi notifikasi (HTML): judul pengumuman tebal di baris pertama,
  /// lalu isi pengumuman.
  final String body;

  /// Payload ketukan (JSON): pengumumanId + url.
  final String payload;
}

/// Susun isi notifikasi lokal dari payload data FCM (lihat Siakad
/// `src/lib/fcm-server.ts`): data.pengirim, data.judul, data.isi,
/// data.url, data.pengumumanId.
PengumumanNotificationContent buildPengumumanNotification(
    Map<String, dynamic> data) {
  final pengirim = _teks(data['pengirim']);
  final judul = _teks(data['judul']);
  final isi = _teks(data['isi']);
  final url = _teks(data['url']);
  final pengumumanId = _teks(data['pengumumanId']);
  final title = pengirim.isEmpty ? 'Pengumuman' : pengirim;
  final body = judul.isEmpty
      ? _escapeHtml(isi)
      : '<b>${_escapeHtml(judul)}</b>${isi.isEmpty ? '' : '<br>${_escapeHtml(isi)}'}';
  return PengumumanNotificationContent(
    title: title,
    body: body,
    payload: jsonEncode({'pengumumanId': pengumumanId, 'url': url}),
  );
}

String _teks(Object? v) => v is String ? v : '';

String _escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// Hasil penguraian payload FCM menjadi aksi navigasi di aplikasi.
/// Fungsi murni (tanpa Firebase) agar mudah diuji.
class PengumumanDeepLink {
  const PengumumanDeepLink(
      {this.pengumumanId, this.externalUrl, this.openInbox = true});

  /// Buka satu pengumuman tertentu di inbox.
  final String? pengumumanId;

  /// Buka tautan eksternal (tautan admin di luar portal).
  final String? externalUrl;

  /// Buka daftar inbox (tanpa item tertentu).
  final bool openInbox;

  bool get isEmpty =>
      pengumumanId == null && externalUrl == null && !openInbox;
}

/// Uraikan `data` notifikasi FCM (lihat Siakad `src/lib/fcm-server.ts`):
/// `data.url` berisi tautan pengumuman (default "/santri/pengumuman"),
/// `data.pengumumanId` berisi id pengumuman atau string kosong.
PengumumanDeepLink resolvePengumumanDeepLink(Map<String, dynamic> data) {
  final id = data['pengumumanId'];
  if (id is String && id.isNotEmpty) {
    return PengumumanDeepLink(pengumumanId: id);
  }
  final url = data['url'];
  if (url is String && url.isNotEmpty) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return PengumumanDeepLink(externalUrl: url, openInbox: false);
    }
  }
  // Tautan relatif portal ("/santri/pengumuman") atau tanpa data:
  // ketukan notifikasi selalu mendarat di inbox.
  return const PengumumanDeepLink();
}

/// Handler pesan latar (isolate terpisah). Pesan FCM kini data-only, jadi
/// sistem tidak menampilkannya otomatis — handler ini yang membangun
/// notifikasi lokalnya (channel HIGH) setelah Firebase siap.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await SantriPush.showPengumumanNotification(message.data);
}

/// Notifikasi push (FCM) untuk santri: minta izin, daftarkan token
/// perangkat ke server, hapus token saat logout, tampilkan pengumuman
/// sebagai notifikasi lokal (heads-up), dan teruskan ketukan notifikasi
/// ke halaman Pengumuman.
///
/// Semua metode menjadi no-op bila Firebase tidak terinisialisasi
/// (mis. build tanpa google-services.json atau di widget test), supaya
/// aplikasi tetap jalan penuh tanpa push.
class SantriPush {
  SantriPush(this.api);

  final SantriApi api;

  /// True bila Firebase berhasil diinisialisasi di main().
  static bool firebaseReady = false;

  /// Jumlah pengumuman belum dibaca (badge bel di portal). Statis agar
  /// halaman Pengumuman bisa menurunkannya setelah menandai dibaca.
  static final unreadCount = ValueNotifier<int>(0);

  /// Id pengumuman yang harus dibuka otomatis begitu halaman Pengumuman
  /// selesai memuat (dari ketukan notifikasi). Dibersihkan setelah dipakai.
  static String? openPengumumanId;

  /// Ketukan notifikasi yang menunggu diproses portal (setelah login).
  final pendingLink = ValueNotifier<PengumumanDeepLink?>(null);

  bool _listenersSet = false;
  String? _lastToken;

  static const _tokenKey = 'siakad.fcm.token.v1';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _localInitialized = false;

  /// Inisialisasi Firebase. Dipanggil sekali dari main() sebelum runApp.
  /// Gagal (mis. google-services.json tidak ada) tidak menggagalkan app.
  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (_) {
      firebaseReady = false;
    }
  }

  /// Inisialisasi notifikasi lokal + channel HIGH (isolate utama).
  /// Ketukan notifikasi diteruskan ke [pendingLink]; bila aplikasi
  /// dibuka lewat ketukan (cold start), payload-nya dibaca di sini.
  Future<void> _initLocalNotifications() async {
    if (_localInitialized) return;
    _localInitialized = true;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          pendingLink.value = resolvePengumumanDeepLink(data);
        } catch (_) {}
      },
    );
    await _createPengumumanChannel();
    final launch = await _local.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        pendingLink.value = resolvePengumumanDeepLink(data);
      } catch (_) {}
    }
  }

  static Future<void> _createPengumumanChannel() async {
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          pengumumanChannelId,
          pengumumanChannelName,
          description: pengumumanChannelDescription,
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(pengumumanSoundName),
        ));
  }

  /// Tampilkan notifikasi pengumuman (channel HIGH, judul = pengirim,
  /// judul pengumuman tebal di isi). Dipakai handler latar (isolate
  /// terpisah) dan pesan foreground. Gagal tampil tidak melempar —
  /// pengumuman tetap ada di inbox portal.
  static Future<void> showPengumumanNotification(
      Map<String, dynamic> data) async {
    try {
      if (!_localInitialized) {
        // Isolate latar punya state statis sendiri, jadi inisialisasi di
        // sini tidak mengganggu callback ketukan isolate utama.
        _localInitialized = true;
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        await _local.initialize(
          settings: const InitializationSettings(android: android),
        );
      }
      await _createPengumumanChannel();
      final content = buildPengumumanNotification(data);
      await _local.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
        title: content.title,
        body: content.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            pengumumanChannelId,
            pengumumanChannelName,
            channelDescription: pengumumanChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound(
                pengumumanSoundName),
            styleInformation: BigTextStyleInformation(
              content.body,
              htmlFormatBigText: true,
              htmlFormatContent: true,
            ),
          ),
        ),
        payload: content.payload,
      );
    } catch (_) {
      // Gagal tampil tidak mengganggu; pengumuman tetap ada di inbox.
    }
  }

  /// Pasang listener pesan + periksa notifikasi yang membuka aplikasi.
  /// Dipanggil sekali, setelah login pertama.
  Future<void> ensureListeners() async {
    if (!firebaseReady || _listenersSet) return;
    _listenersSet = true;
    await _initLocalNotifications();
    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen((message) async {
      // App sedang terbuka: tampilkan juga sebagai heads-up + perbarui badge.
      await showPengumumanNotification(message.data);
      unawaited(refreshUnread());
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    messaging.onTokenRefresh.listen((token) async {
      if (api.session != null) await _registerToken(token);
    });
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleOpenedMessage(initial);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    pendingLink.value = resolvePengumumanDeepLink(message.data);
  }

  /// Minta izin notifikasi (Android 13+ menampilkan dialog sistem) lalu
  /// daftarkan token perangkat ke server. Dipanggil setelah login /
  /// restore sesi berhasil. Idempotent: token yang sama tidak dikirim ulang.
  Future<void> registerAfterLogin() async {
    if (!firebaseReady || api.session == null) return;
    await ensureListeners();
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    if (api.session == null) return;
    try {
      _lastToken ??= await api.vault.read(key: _tokenKey);
      if (_lastToken == token) return; // Sudah terdaftar.
      await api.call('/api/santri/perangkat',
          method: 'POST', body: {'token': token, 'platform': 'android'});
      _lastToken = token;
      await api.vault.write(key: _tokenKey, value: token);
    } catch (_) {
      // Gagal daftar tidak mengganggu sesi; dicoba lagi saat login berikut.
    }
  }

  /// Hapus token perangkat dari server SEBELUM sesi dihapus (logout).
  /// Gagal jaringan tidak menghalangi logout.
  Future<void> unregisterBeforeLogout() async {
    try {
      final token = _lastToken ?? await api.vault.read(key: _tokenKey);
      if (token != null &&
          token.isNotEmpty &&
          api.session != null &&
          firebaseReady) {
        await api.call('/api/santri/perangkat',
            method: 'DELETE', body: {'token': token});
      }
    } catch (_) {}
    _lastToken = null;
    await api.vault.delete(key: _tokenKey);
  }

  /// Muat ulang jumlah belum-dibaca untuk badge bel.
  Future<void> refreshUnread() async {
    if (api.session == null) return;
    try {
      final d = obj(await api.call('/api/santri/pengumuman'));
      final n = d['jumlahBelumDibaca'];
      if (n is num) unreadCount.value = n.toInt();
    } catch (_) {}
  }
}
