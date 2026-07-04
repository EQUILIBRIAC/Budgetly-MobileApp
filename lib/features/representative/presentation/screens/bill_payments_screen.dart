import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/core/utils/currency_utils.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';
import 'package:budgetly_app/features/representative/presentation/providers/bill_payments_provider.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/payments/bill_payment_summary_header.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/payments/member_payment_card.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/representative_dashboard_layout.dart';

class BillPaymentsScreen extends ConsumerStatefulWidget {
  const BillPaymentsScreen({
    required this.billId,
    this.bill,
    super.key,
  });

  final String billId;
  final Bill? bill;

  @override
  ConsumerState<BillPaymentsScreen> createState() => _BillPaymentsScreenState();
}

class _BillPaymentsScreenState extends ConsumerState<BillPaymentsScreen> {
  String? _savingMemberContributionId;

  BillPaymentsParams get _params =>
      BillPaymentsParams(billId: widget.billId, bill: widget.bill);

  Future<void> _confirmAndMarkPaid(MemberPaymentItem item) async {
    final sym = CurrencyUtils.formatSymbol(
      ref.read(representativeProvider).valueOrNull?.currency == 'USD',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Text(
          '¿Confirmar pago de $sym${item.amount.toStringAsFixed(2)} '
          'de ${item.memberName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.dashGreen),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _savingMemberContributionId = item.memberContributionId);
    try {
      await ref.read(billPaymentsActionsProvider).markAsPaid(
            params: _params,
            memberContributionId: item.memberContributionId,
            amount: item.amount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado correctamente')),
      );
    } on MarkPaidEndpointMissingException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiFailure.wrap(e).messageEs)),
      );
    } finally {
      if (mounted) setState(() => _savingMemberContributionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repData = ref.watch(representativeProvider).valueOrNull;
    final sym = CurrencyUtils.formatSymbol(repData?.currency == 'USD');
    final paymentsAsync = ref.watch(billPaymentsProvider(_params));

    return RepresentativeDashboardLayout(
      currentRoute: '',
      child: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: ApiFailure.wrap(e).messageEs,
          onRetry: () => ref.invalidate(billPaymentsProvider(_params)),
        ),
        data: (vm) => SingleChildScrollView(
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
                      'Pagos del gasto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                    ),
                  ),
                ],
              ),
              BillPaymentSummaryHeader(
                billDescription: vm.bill.description,
                billAmount: vm.bill.amount,
                progress: vm.progress,
                currencySymbol: sym,
              ),
              const SizedBox(height: 20),
              Text(
                'Aportes por miembro',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 12),
              if (vm.members.isEmpty)
                const Text('No hay aportes registrados para esta factura.')
              else
                ...vm.members.map(
                  (item) => MemberPaymentCard(
                    item: item,
                    currencySymbol: sym,
                    isSaving:
                        _savingMemberContributionId == item.memberContributionId,
                    onMarkPaid: item.canMarkPaid
                        ? () => _confirmAndMarkPaid(item)
                        : null,
                  ),
                ),
            ],
          ),
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
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
