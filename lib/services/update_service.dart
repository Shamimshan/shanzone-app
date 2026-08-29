import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  // ─── CONFIGURE THIS ────────────────────────────────────────
  static const String _owner = 'Shamimshan';        // ← Your GitHub username
  static const String _repo = 'shanzone-app';       // ← Your repo name
  // ──────────────────────────────────────────────────────────

  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Check if a new version is available on GitHub.
  /// Returns the latest version tag (e.g., "v1.0.2") or null.
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

  /// Download the latest APK from GitHub Release.
  static Future<String?> downloadApk(String versionTag) async {
    try {
      final releaseData = await _getReleaseData(versionTag);
      if (releaseData == null) return null;

      final assets = releaseData['assets'] as List;
      final apkAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset == null) {
        debugPrint('❌ No APK found in release $versionTag');
        return null;
      }

      final downloadUrl = apkAsset['browser_download_url'] as String;

      if (!await _requestStoragePermission()) return null;

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory!.path}/shanzone_$versionTag.apk';
      final file = File(filePath);

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ APK downloaded: $filePath');
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      return null;
    }
  }

  /// Install the downloaded APK using the system installer.
  static Future<bool> installApk(String filePath) async {
    try {
      if (await Permission.requestInstallPackages.isDenied) {
        await Permission.requestInstallPackages.request();
        if (await Permission.requestInstallPackages.isDenied) {
          debugPrint('❌ Install permission denied');
          return false;
        }
      }
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Installation failed: $e');
      return false;
    }
  }

  // ─── Private Helpers ──────────────────────────────────────

  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version; // e.g., "1.0.0"
  }

  static bool _isNewerVersion(String current, String latest) {
    final c = current.replaceAll('v', '');
    final l = latest.replaceAll('v', '');
    try {
      final cParts = c.split('.').map(int.parse).toList();
      final lParts = l.split('.').map(int.parse).toList();
      for (int i = 0; i < cParts.length; i++) {
        if (i >= lParts.length) return false;
        if (lParts[i] > cParts[i]) return true;
        if (lParts[i] < cParts[i]) return false;
      }
      return lParts.length > cParts.length;
    } catch (e) {
      return false;
    }
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
