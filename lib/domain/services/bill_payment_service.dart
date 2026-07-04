import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/domain/entities/member_view_model.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';

/// Cálculo de progreso, deduplicación y merge con nombres de miembros.
abstract final class BillPaymentService {
  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  /// Un registro por `memberId`; prioriza Done y el más reciente.
  static List<MemberContributionDto> dedupeByMemberId(
    List<MemberContributionDto> rows,
  ) {
    final best = <String, MemberContributionDto>{};
    for (final row in rows) {
      if (row.memberId.isEmpty) continue;
      final current = best[row.memberId];
      if (current == null || _shouldPrefer(row, current)) {
        best[row.memberId] = row;
      }
    }
    return best.values.toList();
  }

  static Set<String> activeMemberIds(List<MemberIncomeProfile> profiles) => profiles
      .map((p) => p.householdMemberId)
      .where((id) => id.isNotEmpty)
      .toSet();

  /// Deduplica y conserva solo miembros activos del hogar.
  static List<MemberContributionDto> normalizeForHousehold({
    required List<MemberContributionDto> rows,
    required List<MemberIncomeProfile> activeProfiles,
  }) {
    final allowed = activeMemberIds(activeProfiles);
    return dedupeByMemberId(rows)
        .where((r) => allowed.contains(r.memberId))
        .toList();
  }

  static bool _shouldPrefer(
    MemberContributionDto candidate,
    MemberContributionDto current,
  ) {
    if (candidate.isDone && !current.isDone) return true;
    if (current.isDone && !candidate.isDone) return false;
    if (candidate.payedAt != null && current.payedAt == null) return true;
    if (current.payedAt != null && candidate.payedAt == null) return false;
    return candidate.id.compareTo(current.id) > 0;
  }

  static BillPaymentProgress buildProgress({
    required String billId,
    required double billTotalAmount,
    required List<MemberContributionDto> contributions,
  }) {
    final rows = dedupeByMemberId(contributions);

    if (rows.isEmpty) {
      return BillPaymentProgress.empty(
        billId: billId,
        billTotalAmount: billTotalAmount,
      );
    }

    final totalAssigned = _round2(
      rows.fold<double>(0, (sum, c) => sum + c.amount),
    );
    final paidAmount = _round2(
      rows.where((c) => c.isDone).fold<double>(0, (sum, c) => sum + c.amount),
    );
    final pendingAmount = _round2(totalAssigned - paidAmount);
    final paidMembersCount = rows.where((c) => c.isDone).length;
    final totalMembersCount = rows.length;
    final base = billTotalAmount > 0
        ? billTotalAmount
        : (totalAssigned > 0 ? totalAssigned : 0);
    final progressPercent =
        base > 0 ? _round2((paidAmount / base) * 100) : 0.0;

    return BillPaymentProgress(
      billId: billId,
      billTotalAmount: billTotalAmount,
      totalAssigned: totalAssigned,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      progressPercent: progressPercent,
      paidMembersCount: paidMembersCount,
      totalMembersCount: totalMembersCount,
    );
  }

  static List<MemberPaymentItem> mergeWithMemberNames({
    required List<MemberContributionDto> contributions,
    required List<MemberViewModel> members,
  }) {
    final nameByMemberId = {
      for (final m in members) m.householdMemberId: m.displayName,
    };

    return dedupeByMemberId(contributions).map((c) {
      return MemberPaymentItem(
        memberContributionId: c.id,
        memberId: c.memberId,
        memberName: nameByMemberId[c.memberId] ?? 'Sin nombre',
        amount: c.amount,
        isDone: c.isDone,
        payedAt: c.payedAt,
      );
    }).toList()
      ..sort((a, b) => a.memberName.compareTo(b.memberName));
  }
}
