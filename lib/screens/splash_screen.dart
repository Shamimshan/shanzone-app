import 'package:flutter/material.dart';
import 'package:shanzone_app/services/session_service.dart';
import 'package:shanzone_app/services/update_service.dart';
import 'package:shanzone_app/screens/login_screen.dart';
import 'package:shanzone_app/screens/main_nav_screen.dart';
import 'package:shanzone_app/theme/app_colors.dart';
import 'package:shanzone_app/l10n/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Splash screen ko kam se kam 2 second dikhana hai
    Future.delayed(const Duration(seconds: 2), () {
      _checkForUpdatesAndNavigate();
    });
  }

  Future<void> _checkForUpdatesAndNavigate() async {
    // 1. Pehle update check karein
    String? latestVersion;
    try {
      latestVersion = await UpdateService.checkForUpdate();
    } catch (e) {
      // Agar update check fail ho, toh ignore karein
    }

    // 2. Agar update available hai toh dialog dikhayein
    if (latestVersion != null && mounted) {
      _showUpdateDialog(latestVersion);
    } else {
      // 3. Nahi toh seedha navigate karein (login ya home)
      _navigateToNextScreen();
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
          'Would you like to download and install it now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToNextScreen();
            },
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _startDownload(version);
              // Download/install ke baad app restart ho jayega,
              // isliye yahan navigation ki zaroorat nahi.
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload(String version) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading update...'),
          ],
        ),
      ),
    );

    final path = await UpdateService.downloadApk(version);
    if (mounted) Navigator.pop(context); // close progress dialog

    if (path != null) {
      final installed = await UpdateService.installApk(path);
      if (!installed && mounted) {
        _showErrorDialog('Installation failed. Please open the APK manually.');
      }
      // Agar install ho gaya, app restart ho jaayega
    } else {
      if (mounted) {
        _showErrorDialog(
          'Failed to download the update.\n\n'
          'Please check your internet connection and storage space.',
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
              _navigateToNextScreen();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Original Navigation Logic (Splash → Login / Home) ───
  void _navigateToNextScreen() {
    if (!mounted) return;

    // Check if user is already logged in
    final isLoggedIn = SessionService.isLoggedIn(); // assume this method exists

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ─── UI (Splash Screen Design) ──────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientCenter,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SHAN ZONE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocale.current.value == 'hi'
                  ? 'ब्रॉडबैंड'
                  : 'Broadband',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocale.current.value == 'hi'
                  ? 'लोड हो रहा है...'
                  : 'Loading...',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
