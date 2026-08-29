import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String _owner = 'Shamimshan';
  static const String _repo = 'shanzone-app';
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
      } else {
        debugPrint('⚠️ GitHub API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Update check failed: $e');
      return null;
    }
  }

  static Future<String?> downloadApk(String versionTag) async {
    try {
      if (!await _requestStoragePermission()) {
        debugPrint('❌ Storage permission denied');
        return null;
      }

      final releaseData = await _getReleaseData(versionTag);
      if (releaseData == null) {
        debugPrint('❌ No release data for tag: $versionTag');
        return null;
      }

      final assets = releaseData['assets'] as List;
      if (assets.isEmpty) {
        debugPrint('❌ No assets in release');
        return null;
      }

      final apkAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset == null) {
        debugPrint('❌ No APK found in assets: $assets');
        return null;
      }

      final downloadUrl = apkAsset['browser_download_url'] as String;
      debugPrint('📥 Download URL: $downloadUrl');

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        debugPrint('❌ Could not get external storage directory');
        return null;
      }
      final filePath = '${directory.path}/shanzone_$versionTag.apk';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ APK downloaded: $filePath');
        return filePath;
      } else {
        debugPrint('❌ Download failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Download exception: $e');
      return null;
    }
  }

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

  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
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
    } else {
      debugPrint('⚠️ Release API returned ${response.statusCode} for tag $tag');
      return null;
    }
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
