import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../l10n/app_strings.dart';

/// Everything that needs to survive an app restart (login session,
/// which accounts belong to this device, which one is currently active,
/// saved profile photo URL, and chosen language) lives here.
class SessionService {
  SessionService._();

  static const _kMobile = 'session_mobile';
  static const _kAccounts = 'session_accounts';
  static const _kSelectedUserId = 'session_selected_user_id';
  static const _kPhotoUrl = 'session_photo_url';
  static const _kLang = 'session_lang';

  static Future<void> saveLogin(String mobile, List<Account> accounts, {String photoUrl = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMobile, mobile);
    await prefs.setString(
      _kAccounts,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
    if (photoUrl.isNotEmpty) {
      await prefs.setString(_kPhotoUrl, photoUrl);
    }
    if (accounts.isNotEmpty) {
      await prefs.setString(_kSelectedUserId, accounts.first.userId);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kMobile) && prefs.containsKey(_kAccounts);
  }

  static Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMobile);
  }

  static Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccounts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateAccounts(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kAccounts,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  static Future<String?> getSelectedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelectedUserId);
  }

  static Future<void> setSelectedUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedUserId, userId);
  }

  static Future<String?> getPhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPhotoUrl);
  }

  static Future<void> setPhotoUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhotoUrl, url);
  }

  /// Language choice — restored into AppLocale.current on app start (see main.dart).
  static Future<void> saveLang(AppLang lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, lang == AppLang.hi ? 'hi' : 'en');
  }

  static Future<AppLang> getLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLang) == 'hi' ? AppLang.hi : AppLang.en;
  }

  /// "Remembered device" cache — SEPARATE from the normal session, and
  /// deliberately NOT cleared by logout(). This is what powers the
  /// fingerprint quick-login on the Login screen (skips OTP for a device
  /// that has already verified this mobile number once before).
  static const _kRememberedMobile = 'remembered_mobile';
  static const _kRememberedAccounts = 'remembered_accounts';

  static Future<void> rememberDeviceForBiometric(String mobile, List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRememberedMobile, mobile);
    await prefs.setString(
      _kRememberedAccounts,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  static Future<String?> getRememberedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRememberedMobile);
  }

  static Future<List<Account>> getRememberedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRememberedAccounts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMobile);
    await prefs.remove(_kAccounts);
    await prefs.remove(_kSelectedUserId);
    // Photo aur language jaan-bujh kar delete nahi kar rahe — dobara login
    // karne pe wapas mil jaayenge (achha UX).
  }
}
