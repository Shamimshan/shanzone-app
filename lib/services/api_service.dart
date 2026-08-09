import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/account.dart';

/// All backend calls go through this one place. Backend = the same
/// Google Apps Script Web App used by the website (v9+).
class ApiService {
  ApiService._();

  // Apps Script Web App URL (ends with /exec) — same one the website uses.
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbyzWRsnhYnVX_o9L1eRptc14-cZ3I6_oBbMlug6xspzL7Op_tskH9iXCSVH3XYeAMkYvw/exec';

  static Uri _uri(Map<String, String> params) {
    return Uri.parse(baseUrl).replace(queryParameters: params);
  }

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'text/plain;charset=utf-8'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Sends a 6-digit OTP via SMS to the given 10-digit mobile number.
  static Future<OtpSendResult> sendOtp(String mobile) async {
    try {
      final data = await _post({'action': 'sendOtp', 'mobile': mobile});
      return OtpSendResult(
        success: data['success'] == true,
        message: (data['message'] ?? '').toString(),
      );
    } catch (_) {
      return OtpSendResult(success: false, message: 'network_error');
    }
  }

  /// Verifies the OTP and, on success, returns every account (User ID)
  /// linked to that mobile number, plus the saved profile photo (if any).
  static Future<OtpVerifyResult> verifyOtp(String mobile, String otp) async {
    try {
      final data = await _post({'action': 'verifyOtp', 'mobile': mobile, 'otp': otp});
      final success = data['success'] == true;
      final list = (data['accounts'] as List<dynamic>? ?? [])
          .map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList();
      return OtpVerifyResult(
        success: success,
        message: (data['message'] ?? '').toString(),
        accounts: list,
        photoUrl: (data['photoUrl'] ?? '').toString(),
      );
    } catch (_) {
      return OtpVerifyResult(success: false, message: 'network_error', accounts: const [], photoUrl: '');
    }
  }

  /// Refreshes a single account's full details (plan/expiry/address/photo) —
  /// call this whenever Home/Profile loads, so data is always live from the Sheet.
  static Future<Account?> refreshAccount(String userId) async {
    try {
      final res = await http
          .get(_uri({'action': 'customer', 'userId': userId}))
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['found'] == true) {
        return Account.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Submits an "I've Paid" claim — same PaymentClaims flow as the website.
  static Future<bool> submitPaymentClaim({
    required String userId,
    required String name,
    required String plan,
    required int amount,
  }) async {
    try {
      final data = await _post({
        'userId': userId,
        'name': name,
        'plan': plan,
        'amount': amount,
      });
      final status = (data['status'] ?? '').toString();
      return status == 'ok' || status == 'duplicate';
    } catch (_) {
      return false;
    }
  }

  /// Uploads a new profile photo (base64 JPEG) — saved to Google Drive,
  /// URL stored against this mobile number in the "Profiles" sheet tab.
  static Future<String?> uploadPhoto(String mobile, String imageBase64) async {
    try {
      final data = await _post({
        'action': 'uploadPhoto',
        'mobile': mobile,
        'imageBase64': imageBase64,
      });
      if (data['success'] == true) {
        return (data['photoUrl'] ?? '').toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class OtpSendResult {
  final bool success;
  final String message;
  OtpSendResult({required this.success, required this.message});
}

class OtpVerifyResult {
  final bool success;
  final String message;
  final List<Account> accounts;
  final String photoUrl;
  OtpVerifyResult({
    required this.success,
    required this.message,
    required this.accounts,
    required this.photoUrl,
  });
}
