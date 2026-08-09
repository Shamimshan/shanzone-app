import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shows a horizontal bar representing how much of the ~30-day billing
/// cycle remains. Color shifts green -> orange -> red as expiry nears.
class ExpiryProgressBar extends StatelessWidget {
  final int daysLeft;
  final int cycleDays;

  const ExpiryProgressBar({
    super.key,
    required this.daysLeft,
    this.cycleDays = 30,
  });

  @override
  Widget build(BuildContext context) {
    final clampedDays = daysLeft.clamp(0, cycleDays);
    final fraction = cycleDays == 0 ? 0.0 : clampedDays / cycleDays;

    Color barColor;
    if (daysLeft < 0) {
      barColor = AppColors.danger;
    } else if (daysLeft <= 5) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.success;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 10, color: AppColors.glassFillLight.withOpacity(0.25)),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.03, 1.0),
            child: Container(height: 10, color: barColor),
          ),
        ],
      ),
    );
  }
}
