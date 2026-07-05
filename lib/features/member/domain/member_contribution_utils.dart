import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';

/// Utilidades compartidas para pantallas miembro (aportes / inicio).
abstract final class MemberContributionUtils {
  /// Una fila por gasto/contribution: el API puede devolver duplicados tras resincronizar.
  static List<MemberContribution> dedupeByContribution(
    List<MemberContribution> items, {
    Set<String>? validContributionIds,
    Map<String, Contribution>? contributionsById,
  }) {
    final byKey = <String, MemberContribution>{};

    for (final item in items) {
      final contributionId = item.contributionId.trim();
      if (contributionId.isEmpty) continue;
      if (validContributionIds != null &&
          validContributionIds.isNotEmpty &&
          !validContributionIds.contains(contributionId)) {
        continue;
      }

      final key = _groupKey(
        item,
        contributionsById ?? const {},
      );
      final existing = byKey[key];
      if (existing == null || _prefer(item, existing)) {
        byKey[key] = item;
      }
    }

    final result = byKey.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  static String _groupKey(
    MemberContribution item,
    Map<String, Contribution> contributionsById,
  ) {
    final billId = contributionsById[item.contributionId]?.billId.trim() ?? '';
    if (billId.isNotEmpty) return 'bill:$billId';
    return 'contrib:${item.contributionId}';
  }

  static bool _prefer(MemberContribution candidate, MemberContribution current) {
    if (candidate.isPaid != current.isPaid) {
      return candidate.isPaid;
    }
    if (candidate.payedAt != null && current.payedAt == null) {
      return true;
    }
    return candidate.id.compareTo(current.id) > 0;
  }

  static String labelFor(
    MemberContribution item, {
    required Map<String, Contribution> contributionsById,
    required Map<String, Bill> billsById,
  }) {
    final contribution = contributionsById[item.contributionId];
    final desc = contribution?.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;

    final billId = contribution?.billId;
    if (billId != null && billId.isNotEmpty) {
      final billDesc = billsById[billId]?.description.trim();
      if (billDesc != null && billDesc.isNotEmpty) {
        return billDesc[0].toUpperCase() + billDesc.substring(1);
      }
    }

    final id = item.id;
    if (id.length <= 12) return 'Aporte $id';
    return 'Aporte ${id.substring(id.length - 8)}';
  }

  static DateTime dueDate(
    MemberContribution item, {
    required Map<String, Contribution> contributionsById,
    required Map<String, Bill> billsById,
  }) {
    final contribution = contributionsById[item.contributionId];
    if (contribution != null) {
      return contribution.deadlineForMembers;
    }
    final billId = contribution?.billId;
    if (billId != null) {
      final payment = billsById[billId]?.paymentDay;
      if (payment != null) return payment;
    }
    return item.updatedAt;
  }

  static DateTime periodDate(
    MemberContribution item, {
    required Map<String, Contribution> contributionsById,
    required Map<String, Bill> billsById,
  }) {
    final contribution = contributionsById[item.contributionId];
    final billId = contribution?.billId;
    if (billId != null && billId.isNotEmpty) {
      final payment = billsById[billId]?.paymentDay;
      if (payment != null) return payment;
    }
    if (contribution != null) {
      return contribution.deadlineForMembers;
    }
    return item.createdAt;
  }
}
