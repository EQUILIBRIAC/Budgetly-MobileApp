import 'package:flutter/material.dart';

import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/payments/payment_progress_bar.dart';

class BillPaymentSummaryHeader extends StatelessWidget {
  const BillPaymentSummaryHeader({
    required this.billDescription,
    required this.billAmount,
    required this.progress,
    required this.currencySymbol,
    super.key,
  });

  final String billDescription;
  final double billAmount;
  final BillPaymentProgress progress;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              billDescription,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '$currencySymbol${billAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.dashGreen,
              ),
            ),
            const SizedBox(height: 16),
            PaymentProgressBar(progressPercent: progress.progressPercent),
            const SizedBox(height: 10),
            Text(
              '${progress.paidMembersCount} de ${progress.totalMembersCount} miembros pagaron',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pagado $currencySymbol${progress.paidAmount.toStringAsFixed(2)} '
              'de $currencySymbol${billAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textGray),
            ),
            if (progress.progressPercent > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${progress.progressPercent.toStringAsFixed(0)}% completado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: progress.isFullyPaid
                      ? AppColors.dashGreen
                      : AppColors.dashOrange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
