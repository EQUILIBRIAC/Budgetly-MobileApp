import 'package:flutter/material.dart';

import 'package:budgetly_app/app/theme/app_colors.dart';

class PaymentProgressBar extends StatelessWidget {
  const PaymentProgressBar({
    required this.progressPercent,
    this.height = 8,
    this.compact = false,
    super.key,
  });

  final double progressPercent;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final clamped = progressPercent.clamp(0, 100) / 100;
    final color = clamped >= 1
        ? AppColors.dashGreen
        : (compact ? AppColors.dashOrange : AppColors.dashBlue);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        backgroundColor: AppColors.borderGray,
        color: color,
      ),
    );
  }
}
