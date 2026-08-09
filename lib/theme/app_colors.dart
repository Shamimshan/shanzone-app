import 'package:flutter/material.dart';

/// Central color palette — matches the exact hex values provided for
/// the Shan Zone app design (purple gradient brand identity).
class AppColors {
  AppColors._();

  // Background gradient (left -> center -> right)
  static const Color gradientLeft = Color(0xFF492AA2); // Dark purple
  static const Color gradientCenter = Color(0xFF5D3AAE); // Center purple
  static const Color gradientRight = Color(0xFF7B54BF); // Light purple

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientLeft, gradientCenter, gradientRight],
  );

  // Text / icons
  static const Color white = Color(0xFFFFFFFF);
  static const Color placeholderText = Color(0xFFC9B8E9);
  static const Color secondaryText = Color(0xFFCDBFE8);

  // Buttons
  static const Color loginButtonBg = Color(0xFFFFFFFF);
  static const Color loginButtonText = Color(0xFF5B36B0);

  // Glass-effect surfaces
  static const Color glassFill = Color(0x598E6AD0); // #8E6AD0 @ ~35%
  static const Color glassFillLight = Color(0x408E6AD0); // ~25%

  static const Color fingerprintCircle = Color(0x4D8B6ACF); // ~30%
  static const Color shadowColor = Color(0x332C136E); // ~20%

  // Functional colors (reused across Home/Profile/Speed Test screens)
  static const Color success = Color(0xFF3DDC84);
  static const Color warning = Color(0xFFFFA31A);
  static const Color danger = Color(0xFFFF4A4A);
  static const Color surfaceLight = Color(0xFFF6F3FC);
  static const Color textDark = Color(0xFF241645);
  static const Color textMuted = Color(0xFF7C71A0);
}
