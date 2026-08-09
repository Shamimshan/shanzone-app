import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'screens/splash_screen.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // App restart hone pe bhi user ki last-chuni hui language yaad rahe.
  AppLocale.current.value = await SessionService.getLang();
  runApp(const ShanZoneApp());
}

class ShanZoneApp extends StatelessWidget {
  const ShanZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHAN ZONE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
