/// Authentication and santri access remain owned by the existing website.
class SiakadPortal {
  SiakadPortal(String baseUrl, {bool allowLocalHttp = false}) {
    final uri = Uri.parse(baseUrl.trim());
    final local =
        const {'localhost', '127.0.0.1', '10.0.2.2', '::1'}.contains(uri.host);
    if (uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'https' &&
            !(allowLocalHttp && local && uri.scheme == 'http'))) {
      throw const FormatException('Alamat portal harus menggunakan HTTPS.');
    }
    origin = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null);
  }
  static const title = 'SIAKAD Markaz Arabiyah Tech';
  static const defaultBaseUrl = 'https://siakad.markazarabiyah.site';
  late final Uri origin;
  Uri get dashboard => origin.resolve('/santri/dashboard');
  Uri get login => origin.resolve('/santri/login');
  bool owns(Uri uri) =>
      uri.userInfo.isEmpty &&
      uri.scheme == origin.scheme &&
      uri.host == origin.host &&
      uri.port == origin.port;
  bool isLogin(Uri uri) => owns(uri) && uri.path == '/santri/login';
  bool isSantriPage(Uri uri) =>
      owns(uri) && uri.path.startsWith('/santri/') && !isLogin(uri);
  static bool canOpenExternally(Uri uri) =>
      const {'https', 'http', 'mailto', 'tel', 'whatsapp'}.contains(uri.scheme);
}
