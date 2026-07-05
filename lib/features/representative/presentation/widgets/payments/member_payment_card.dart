import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';

class MemberPaymentCard extends StatelessWidget {
  const MemberPaymentCard({
    required this.item,
    required this.currencySymbol,
    required this.onMarkPaid,
    this.isSaving = false,
    super.key,
  });

  final MemberPaymentItem item;
  final String currencySymbol;
  final VoidCallback? onMarkPaid;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final initial = item.memberName.isNotEmpty
        ? item.memberName[0].toUpperCase()
        : '?';
    final paidDate = item.payedAt != null
        ? DateFormat('dd/MM/yyyy').format(item.payedAt!)
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isDone
              ? AppColors.dashGreen.withValues(alpha: 0.35)
              : AppColors.borderGray,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.isDone
                      ? AppColors.dashGreen.withValues(alpha: 0.15)
                      : AppColors.dashOrange.withValues(alpha: 0.15),
                  child: item.isDone
                      ? const Icon(Icons.check, color: AppColors.dashGreen, size: 20)
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.dashOrange,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currencySymbol${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.dashGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(isDone: item.isDone, l: l),
              ],
            ),
            if (paidDate != null) ...[
              const SizedBox(height: 8),
              Text(
                l.t('Pagado el $paidDate', 'Paid on $paidDate'),
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            ],
            if (item.canMarkPaid) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isSaving ? null : onMarkPaid,
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(l.t('Marcar como pagada', 'Mark as paid')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dashGreen,
                  side: const BorderSide(color: AppColors.dashGreen),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isDone, required this.l});

  final bool isDone;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.dashGreen.withValues(alpha: 0.12)
            : AppColors.dashOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isDone ? l.t('Pagada', 'Paid') : l.pending,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDone ? AppColors.dashGreen : AppColors.dashOrange,
        ),
      ),
    );
  }
}
