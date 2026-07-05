import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/core/utils/currency_utils.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/features/representative/presentation/providers/bill_detail_provider.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/representative_dashboard_layout.dart';

class BillContributionBreakdownScreen extends ConsumerWidget {
  const BillContributionBreakdownScreen({
    required this.billId,
    this.bill,
    super.key,
  });

  final String billId;
  final Bill? bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repData = ref.watch(representativeProvider).valueOrNull;
    final currency = repData?.currency ?? 'PEN';
    final sym = CurrencyUtils.formatSymbol(currency == 'USD');

    final params = BillDetailParams(billId: billId, bill: bill);
    final breakdownAsync = ref.watch(billDetailProvider(params));

    return RepresentativeDashboardLayout(
      currentRoute: '',
      child: breakdownAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: ApiFailure.wrap(e).messageEs,
          onRetry: () => ref.invalidate(billDetailProvider(params)),
        ),
        data: (vm) => _BreakdownBody(viewModel: vm, currencySymbol: sym),
      ),
    );
  }
}

class _BreakdownBody extends StatelessWidget {
  const _BreakdownBody({
    required this.viewModel,
    required this.currencySymbol,
  });

  final BillBreakdownViewModel viewModel;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bill = viewModel.bill;
    final dateFmt = DateFormat('yyyy-MM-dd');
    final due = bill.paymentDate == null
        ? l.t('Sin fecha', 'No date')
        : dateFmt.format(bill.paymentDate!);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  bill.description,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.borderGray),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$currencySymbol${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dashGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l.t('Vencimiento: $due', 'Due: $due')),
                  const SizedBox(height: 12),
                  _StrategyBadge(strategy: viewModel.strategy),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.t('Desglose por miembro', 'Breakdown by member'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 12),
          if (viewModel.items.isEmpty)
            Text(l.t('No hay miembros para repartir este gasto.', 'No members to split this expense.'))
          else
            ...viewModel.items.map(
              (item) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderGray),
                ),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    l.t(
                      '${item.percentage.toStringAsFixed(1)}% del ingreso del hogar',
                      '${item.percentage.toStringAsFixed(1)}% of household income',
                    ),
                  ),
                  trailing: Text(
                    '$currencySymbol${item.assignedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.dashGreen,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: AppColors.dashBadgeBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                l.totalAssigned,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                '$currencySymbol${viewModel.totalAssigned.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: viewModel.totalsMatch
                      ? AppColors.dashGreen
                      : AppColors.dangerRed,
                ),
              ),
              subtitle: viewModel.totalsMatch
                  ? Text(l.t('Coincide con el monto de la factura', 'Matches bill amount'))
                  : Text(
                      l.t(
                        'Factura: $currencySymbol${bill.amount.toStringAsFixed(2)}',
                        'Bill: $currencySymbol${bill.amount.toStringAsFixed(2)}',
                      ),
                      style: const TextStyle(color: AppColors.dangerRed),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategyBadge extends StatelessWidget {
  const _StrategyBadge({required this.strategy});

  final EStrategy strategy;

  @override
  Widget build(BuildContext context) {
    final isIncome = strategy == EStrategy.incomeBased;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isIncome
            ? AppColors.dashGreen.withValues(alpha: 0.15)
            : AppColors.dashBadgeBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        strategy.label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isIncome ? AppColors.dashGreen : AppColors.dashBlue,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
