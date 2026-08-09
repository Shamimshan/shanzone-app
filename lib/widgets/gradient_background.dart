import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-screen purple gradient wrapper with a few soft decorative
/// circles for visual depth (matches the provided Figma-style spec).
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _softCircle(180),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _softCircle(220),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }

  Widget _softCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
