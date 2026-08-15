import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../l10n/app_strings.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/animated_otp_verifier.dart';
import 'main_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { mobile, otp }

class _LoginScreenState extends State<LoginScreen> {
  final _mobileCtrl = TextEditingController();
  final _localAuth = LocalAuthentication();

  _Step step = _Step.mobile;
  bool loading = false;
  String? error;
  String? rememberedMobile;
  int resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _checkRememberedDevice();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkRememberedDevice() async {
    final mobile = await SessionService.getRememberedMobile();
    if (mobile != null && mounted) {
      setState(() => rememberedMobile = mobile);
    }
  }

  void _startCooldown() {
    setState(() => resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendCooldown <= 1) {
        t.cancel();
        setState(() => resendCooldown = 0);
      } else {
        setState(() => resendCooldown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10) {
      setState(() => error = S.of('invalidMobile'));
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });

    final result = await ApiService.sendOtp(mobile);

    if (!mounted) return;
    setState(() => loading = false);

    if (result.success) {
      setState(() => step = _Step.otp);
      _startCooldown();
    } else {
      setState(() {
        error = result.message.isNotEmpty ? result.message : S.of('somethingWrong');
      });
    }
  }

  /// Called by the animated OTP widget once all 4 digits are entered.
  /// Returns true only after the account data is fully saved, so the
  /// widget's success animation and the real login are always in sync.
  Future<bool> _handleOtpSubmit(String otp) async {
    final mobile = _mobileCtrl.text.trim();
    final result = await ApiService.verifyOtp(mobile, otp);

    if (result.success && result.accounts.isNotEmpty) {
      await SessionService.saveLogin(mobile, result.accounts, photoUrl: result.photoUrl);
      await SessionService.rememberDeviceForBiometric(mobile, result.accounts);
      return true;
    }
    return false;
  }

  void _goToMainNav() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
  }

  Future<void> _biometricLogin() async {
    if (rememberedMobile == null) return;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Login to SHAN ZONE',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (!ok) return;

      setState(() => loading = true);
      final accounts = await SessionService.getRememberedAccounts();
      final photoUrl = await SessionService.getPhotoUrl() ?? '';

      // Fresh data refresh from the Sheet before entering (in case plan/expiry changed)
      final refreshed = <Account>[];
      for (final acc in accounts) {
        final fresh = await ApiService.refreshAccount(acc.userId);
        refreshed.add(fresh ?? acc);
      }

      await SessionService.saveLogin(rememberedMobile!, refreshed, photoUrl: photoUrl);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } catch (_) {
      if (mounted) setState(() => error = S.of('somethingWrong'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: ValueListenableBuilder<AppLang>(
          valueListenable: AppLocale.current,
          builder: (context, _, __) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.wifi_rounded,
                            size: 34, color: AppColors.gradientCenter),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        S.of('welcomeBack'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step == _Step.mobile
                            ? S.of('loginSubtitle')
                            : '${S.of('otpSentTo')} +91 ${_mobileCtrl.text}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 34),
                      if (step == _Step.mobile) ..._buildMobileStep(),
                      if (step == _Step.otp) ..._buildOtpStep(),
                      if (error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          error!,
                          style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 12.5),
                        ),
                      ],
                      if (step == _Step.mobile && rememberedMobile != null) ...[
                        const SizedBox(height: 34),
                        _buildBiometricOption(),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: const LanguageToggleButton(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildMobileStep() {
    return [
      Text(S.of('mobileNumber'),
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      GlassTextField(
        controller: _mobileCtrl,
        hint: '10-digit mobile number',
        keyboardType: TextInputType.phone,
        maxLength: 10,
        prefixIcon: Icons.phone_android_rounded,
      ),
      const SizedBox(height: 22),
      _buildPrimaryButton(
        label: S.of('sendOtp'),
        onTap: loading ? null : _sendOtp,
      ),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
      Text(S.of('enterOtp'),
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      AnimatedOtpVerifier(
        length: 4,
        onSubmit: _handleOtpSubmit,
        onVerified: _goToMainNav,
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => setState(() {
              step = _Step.mobile;
              error = null;
            }),
            child: Text(S.of('changeNumber'),
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 12.5)),
          ),
          TextButton(
            onPressed: resendCooldown == 0 ? _sendOtp : null,
            child: Text(
              resendCooldown == 0 ? S.of('resendOtp') : '${S.of('resendOtp')} (${resendCooldown}s)',
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildBiometricOption() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR LOGIN WITH',
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 11, letterSpacing: 1)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: loading ? null : _biometricLogin,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.fingerprintCircle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.fingerprint, color: Colors.white, size: 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.loginButtonBg,
          foregroundColor: AppColors.loginButtonText,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.loginButtonText),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}
