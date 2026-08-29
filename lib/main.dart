import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'l10n/app_strings.dart';
import 'screens/speedtest_screen.dart';
import 'services/session_service.dart';
import 'services/update_service.dart';
import 'theme/app_theme.dart';

// ─── Splash Screen ──────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Splash screen ko kam se kam 2 second dikhao
    await Future.delayed(const Duration(seconds: 2));

    final latestVersion = await UpdateService.checkForUpdate();
    if (latestVersion != null && mounted) {
      _showUpdateDialog(latestVersion);
    } else {
      _goToHome();
    }
  }

  void _showUpdateDialog(String version) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Update Available'),
        content: Text(
          'Version **$version** is ready.\n\n'
          'Would you like to download and install it now?\n'
          '(Internet connection required)',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToHome();
            },
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _startDownload(version);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload(String version) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Downloading update $version...'),
          ],
        ),
      ),
    );

    final path = await UpdateService.downloadApk(version);
    if (mounted) Navigator.pop(context); // close progress

    if (path != null) {
      final installed = await UpdateService.installApk(path);
      if (!installed && mounted) {
        _showErrorDialog('Installation failed. Please open the APK manually.');
      }
    } else {
      if (mounted) {
        _showErrorDialog(
          'Failed to download the update.\n\n'
          'Please check your internet connection and storage space.\n'
          'You can also download the APK manually from the GitHub release.',
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToHome();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SpeedTestScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo – if you have an asset, use Image.asset; otherwise text
            const Icon(
              Icons.wifi,
              size: 80,
              color: Color(0xFF5D3AAE),
            ),
            const SizedBox(height: 20),
            const Text(
              'SHAN ZONE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D3AAE),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Broadband',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocale.current.value == 'hi'
                  ? 'जाँच हो रही है...'
                  : 'Checking for updates...',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main ──────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
