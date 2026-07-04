import 'package:budgetly_app/domain/entities/income_split_entities.dart';

/// Progreso de cobro de una factura compartida.
class BillPaymentProgress {
  final String billId;
  final double billTotalAmount;
  final double totalAssigned;
  final double paidAmount;
  final double pendingAmount;
  final double progressPercent;
  final int paidMembersCount;
  final int totalMembersCount;

  const BillPaymentProgress({
    required this.billId,
    required this.billTotalAmount,
    required this.totalAssigned,
    required this.paidAmount,
    required this.pendingAmount,
    required this.progressPercent,
    required this.paidMembersCount,
    required this.totalMembersCount,
  });

  bool get isFullyPaid =>
      totalMembersCount > 0 && paidMembersCount >= totalMembersCount;

  factory BillPaymentProgress.empty({
    required String billId,
    required double billTotalAmount,
  }) {
    return BillPaymentProgress(
      billId: billId,
      billTotalAmount: billTotalAmount,
      totalAssigned: 0,
      paidAmount: 0,
      pendingAmount: 0,
      progressPercent: 0,
      paidMembersCount: 0,
      totalMembersCount: 0,
    );
  }
}

/// Fila de pago por miembro en la UI.
class MemberPaymentItem {
  final String memberContributionId;
  final String memberId;
  final String memberName;
  final double amount;
  final bool isDone;
  final DateTime? payedAt;

  const MemberPaymentItem({
    required this.memberContributionId,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.isDone,
    this.payedAt,
  });

  bool get canMarkPaid => !isDone && memberContributionId.isNotEmpty;
}

/// Vista completa para pantalla de pagos por factura.
class BillPaymentsViewModel {
  final BillDto bill;
  final ContributionDto contribution;
  final BillPaymentProgress progress;
  final List<MemberPaymentItem> members;

  const BillPaymentsViewModel({
    required this.bill,
    required this.contribution,
    required this.progress,
    required this.members,
  });
}

/// Recurso no encontrado al marcar pago (404).
class MarkPaidEndpointMissingException implements Exception {
  const MarkPaidEndpointMissingException();

  @override
  String toString() => 'No se encontró el aporte del miembro.';
}
