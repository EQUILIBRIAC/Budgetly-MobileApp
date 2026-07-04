import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';
import 'package:budgetly_app/features/representative/data/member_contribution_api_service.dart';
import 'package:budgetly_app/features/representative/domain/bill_payment_load_service.dart';
import 'package:budgetly_app/features/representative/presentation/providers/contribution_overview_provider.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';

class BillPaymentsParams {
  const BillPaymentsParams({
    required this.billId,
    this.bill,
  });

  final String billId;
  final Bill? bill;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillPaymentsParams &&
          billId == other.billId &&
          bill?.id == other.bill?.id;

  @override
  int get hashCode => Object.hash(billId, bill?.id);
}

final billPaymentLoadServiceProvider =
    FutureProvider<BillPaymentLoadService>((ref) async {
  return BillPaymentLoadService.authorized();
});

final billPaymentsProvider = FutureProvider.family<
    BillPaymentsViewModel,
    BillPaymentsParams>((ref, params) async {
  final repData = await ref.watch(representativeProvider.future);
  final loader = await ref.watch(billPaymentLoadServiceProvider.future);

  Bill bill;
  if (params.bill != null) {
    bill = params.bill!;
  } else {
    final match = repData.bills.where((b) => b.id == params.billId);
    if (match.isEmpty) {
      throw Exception('No se encontró la factura.');
    }
    bill = match.first;
  }

  return loader.load(bill: bill);
});

final billsPaymentProgressProvider =
    FutureProvider<Map<String, BillPaymentProgress>>((ref) async {
  final repData = await ref.watch(representativeProvider.future);
  final loader = await ref.watch(billPaymentLoadServiceProvider.future);

  final map = <String, BillPaymentProgress>{};
  for (final bill in repData.bills) {
    map[bill.id] = await loader.loadProgressForBill(bill);
  }
  return map;
});

class BillPaymentsActions {
  BillPaymentsActions(this._ref);

  final Ref _ref;

  Future<void> markAsPaid({
    required BillPaymentsParams params,
    required String memberContributionId,
    required double amount,
  }) async {
    final api = await MemberContributionApiService.authorized();
    await api.markAsPaid(
      memberContributionId: memberContributionId,
      amount: amount,
    );
    _ref.invalidate(billPaymentsProvider(params));
    _ref.invalidate(billsPaymentProgressProvider);
    _ref.invalidate(contributionsOverviewProvider);
  }
}

final billPaymentsActionsProvider =
    Provider<BillPaymentsActions>((ref) => BillPaymentsActions(ref));
