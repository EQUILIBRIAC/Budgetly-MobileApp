import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/features/representative/presentation/providers/contribution_providers.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';

class BillDetailParams {
  const BillDetailParams({
    required this.billId,
    this.bill,
  });

  final String billId;
  final Bill? bill;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillDetailParams &&
          billId == other.billId &&
          bill?.id == other.bill?.id;

  @override
  int get hashCode => Object.hash(billId, bill?.id);
}

final billDetailProvider = FutureProvider.family<
    BillBreakdownViewModel,
    BillDetailParams>((ref, params) async {
  final repData = await ref.watch(representativeProvider.future);
  final sync = await ref.read(contributionSyncServiceProvider.future);

  BillDto bill;
  if (params.bill != null) {
    bill = BillDto.fromBill(params.bill!);
  } else {
    final match = repData.bills.where((b) => b.id == params.billId);
    if (match.isEmpty) {
      throw Exception('No se encontró la factura.');
    }
    bill = BillDto.fromBill(match.first);
  }

  return sync.loadOrCreateBreakdown(bill: bill);
});
