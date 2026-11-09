import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/push_service.dart';
import 'theme/markaz_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await dotenv.load(fileName: '.env');
  // Push FCM santri: gagal init (mis. tanpa google-services.json) tidak
  // menggagalkan app — notifikasi tinggal nonaktif.
  await SantriPush.initFirebase();
  if (SantriPush.firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIAKAD Markaz Arabiyah',
      debugShowCheckedModeBanner: false,
      theme: markazTheme(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const MainLayout(),
    );
  }
}
