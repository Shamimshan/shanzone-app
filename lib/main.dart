import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'l10n/app_strings.dart';
import 'screens/speedtest_screen.dart'; // ← Replace with your actual home screen
import 'services/session_service.dart';
import 'theme/app_theme.dart';

// ─── Update Service (inline for simplicity) ──────────────────
class UpdateService {
  static const String _owner = 'YOUR_GITHUB_USERNAME'; // ⚠️ CHANGE THIS
  static const String _repo = 'shanzone_app';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static Future<String?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestTag = data['tag_name'] as String;
        final currentVersion = await _getCurrentVersion();
        return _isNewerVersion(currentVersion, latestTag) ? latestTag : null;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Update check failed: $e');
      return null;
    }
  }

  static Future<String?> downloadApk(String versionTag) async {
    try {
      final releaseData = await _getReleaseData(versionTag);
      if (releaseData == null) return null;

      final assets = releaseData['assets'] as List;
      final apkAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset == null) return null;

      final downloadUrl = apkAsset['browser_download_url'] as String;

      if (!await _requestStoragePermission()) return null;

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/shanzone_$versionTag.apk';
      final file = File(filePath);

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      return null;
    }
  }

  static Future<bool> installApk(String filePath) async {
    try {
      if (await Permission.requestInstallPackages.isDenied) {
        await Permission.requestInstallPackages.request();
        if (await Permission.requestInstallPackages.isDenied) return false;
      }
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Installation failed: $e');
      return false;
    }
  }

  // ─── Private helpers ──────────────────────────────────────

  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static bool _isNewerVersion(String current, String latest) {
    final c = current.replaceAll('v', '');
    final l = latest.replaceAll('v', '');
    final cParts = c.split('.').map(int.parse).toList();
    final lParts = l.split('.').map(int.parse).toList();
    for (int i = 0; i < cParts.length; i++) {
      if (i >= lParts.length) return false;
      if (lParts[i] > cParts[i]) return true;
      if (lParts[i] < cParts[i]) return false;
    }
    return lParts.length > cParts.length;
  }

  static Future<Map<String, dynamic>?> _getReleaseData(String tag) async {
    final url = 'https://api.github.com/repos/$_owner/$_repo/releases/tags/$tag';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
  }
}

// ─── Splash Screen with Update Check ──────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Wait a moment to let the splash screen show
    await Future.delayed(const Duration(seconds: 1));

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
        title: const Text('Update Available 🚀'),
        content: Text(
          'A new version ($version) is available.\nWould you like to download and install it now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToHome();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show progress indicator (optional)
              final path = await UpdateService.downloadApk(version);
              if (path != null) {
                await UpdateService.installApk(path);
                // After installation, the app will restart
              } else {
                _showErrorDialog('Failed to download the update.');
              }
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SpeedTestScreen()),
      // ⚠️ Replace with your actual home screen widget
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SHAN ZONE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D3AAE),
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocale.current.value == 'hi' ? 'जाँच हो रही है...' : 'Checking for updates...',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main App ──────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Remember the user's last chosen language
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
      home: const SplashScreen(), // ← now checks for updates
    );
  }
}
