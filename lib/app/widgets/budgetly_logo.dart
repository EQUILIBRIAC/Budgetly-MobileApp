import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo de marca Budgetly: hogar + presupuesto compartido.
class BudgetlyLogo extends StatelessWidget {
  const BudgetlyLogo({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.iconOnly = false,
    this.wordmarkColor,
    this.useAssetImage = true,
  });

  static const assetPath = 'assets/images/budgetly_logo.png';

  final double size;
  final bool showWordmark;
  final bool iconOnly;
  final Color? wordmarkColor;
  final bool useAssetImage;

  @override
  Widget build(BuildContext context) {
    final mark = _buildMark();

    if (iconOnly || !showWordmark) {
      return mark;
    }

    final textColor = wordmarkColor ??
        Theme.of(context).colorScheme.onSurface.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.95
                  : 1,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.22),
        Text(
          'Budgetly',
          style: TextStyle(
            fontSize: size * 0.48,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMark() {
    if (useAssetImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _LogoMark(size: size),
        ),
      );
    }
    return _LogoMark(size: size);
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mint,
            AppColors.teal,
            AppColors.navy,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.35),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white.withValues(alpha: 0.95),
            size: size * 0.46,
          ),
          Positioned(
            right: size * 0.14,
            bottom: size * 0.12,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: size * 0.04,
                ),
              ),
              child: Icon(
                Icons.home_rounded,
                size: size * 0.16,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
