import 'package:flutter/services.dart';

class ExamGuard {
  static const channel = MethodChannel('markaz/exam');
  static Future<void> begin() async {
    try {
      final active = await channel.invokeMethod<bool>('begin');
      if (active != true)
        throw PlatformException(
            code: 'unavailable', message: 'Mode ujian terkunci belum aktif.');
    } on MissingPluginException {
      throw PlatformException(
          code: 'unsupported',
          message:
              'Mode ujian terkunci hanya tersedia pada Android/iOS yang telah dikonfigurasi.');
    }
  }

  static Future<void> end() async {
    await channel.invokeMethod<void>('end');
  }

  static Future<bool> active() async =>
      await channel.invokeMethod<bool>('active') ?? false;
}
