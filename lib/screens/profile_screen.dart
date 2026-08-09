import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/language_toggle_button.dart';
import 'login_screen.dart';

const String kWhatsappSupportNumber = '916391224488'; // country code + number

class ProfileScreen extends StatefulWidget {
  final Account account;
  const ProfileScreen({super.key, required this.account});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? photoUrl;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    SessionService.getPhotoUrl().then((url) {
      if (mounted) setState(() => photoUrl = url);
    });
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppColors.gradientCenter),
              title: Text(S.of('camera')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.gradientCenter),
              title: Text(S.of('gallery')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
    if (picked == null) return;

    setState(() => uploading = true);
    final bytes = await File(picked.path).readAsBytes();
    final base64Str = base64Encode(bytes);
    final url = await ApiService.uploadPhoto(widget.account.mobile, base64Str);
    if (url != null) {
      await SessionService.setPhotoUrl(url);
      if (mounted) setState(() => photoUrl = url);
    }
    if (mounted) setState(() => uploading = false);
  }

  Future<void> _openWhatsapp() async {
    final uri = Uri.parse('https://wa.me/$kWhatsappSupportNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of('logout')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.of('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.of('ok'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await SessionService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.account;
    final isHindi = AppLocale.current.value == AppLang.hi;
    final displayName = isHindi && acc.nameHi.isNotEmpty ? acc.nameHi : acc.name;
    final displayAddress = isHindi && acc.addressHi.isNotEmpty ? acc.addressHi : acc.address;

    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: LanguageToggleButton(
                      foreground: AppColors.gradientCenter,
                      background: AppColors.surfaceLight,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ---- Editable photo ----
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.glassFillLight,
                        backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                            ? NetworkImage(photoUrl!)
                            : null,
                        child: (photoUrl == null || photoUrl!.isEmpty)
                            ? const Icon(Icons.person_rounded, size: 52, color: AppColors.gradientCenter)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: uploading ? null : _pickPhoto,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.gradientCenter,
                              shape: BoxShape.circle,
                            ),
                            child: uploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ---- Name ----
                  Text(
                    displayName.isEmpty ? '—' : displayName,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    acc.userId,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: AppColors.textMuted.withOpacity(0.2), thickness: 1),
                  const SizedBox(height: 20),

                  // ---- Locked fields ----
                  _ProfileField(
                    icon: Icons.phone_rounded,
                    label: S.of('mobile'),
                    value: acc.mobile,
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    icon: Icons.location_on_rounded,
                    label: S.of('address'),
                    value: displayAddress.isEmpty ? '—' : displayAddress,
                  ),

                  const SizedBox(height: 30),

                  // ---- WhatsApp support ----
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openWhatsapp,
                      icon: const Icon(Icons.chat_rounded),
                      label: Text(S.of('whatsappSupport'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                    label: Text(S.of('logout'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gradientCenter, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 16),
        ],
      ),
    );
  }
}
