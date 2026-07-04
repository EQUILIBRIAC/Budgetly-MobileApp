import 'package:budgetly_app/domain/entities/income_split_entities.dart';

/// Cálculo proporcional IncomeBased y reparto Even (lógica en Flutter).
abstract final class IncomeSplitService {
  static double _round2(double value) =>
      (value * 100).roundToDouble() / 100;

  /// Porcentaje = (income / totalIncome) * 100 por miembro activo.
  static List<MemberIncomeProfile> calculatePercentages(
    List<MemberIncomeProfile> members,
  ) {
    final totalIncome = members.fold<double>(0, (sum, m) => sum + m.income);
    if (totalIncome <= 0) {
      return members.map((m) => m.copyWith(percentage: 0)).toList();
    }
    return members
        .map(
          (m) => m.copyWith(
            percentage: _round2((m.income / totalIncome) * 100),
          ),
        )
        .toList();
  }

  /// memberShare = billAmount * (income / totalIncome), redondeo 2 decimales.
  static List<BillBreakdownItem> calculateIncomeBasedSplit(
    double billAmount,
    List<MemberIncomeProfile> members,
  ) {
    final active = members.where((m) => m.income > 0).toList();
    final totalIncome = active.fold<double>(0, (sum, m) => sum + m.income);
    if (totalIncome <= 0 || billAmount <= 0 || active.isEmpty) {
      return const [];
    }

    final items = active
        .map(
          (m) => BillBreakdownItem(
            householdMemberId: m.householdMemberId,
            userId: m.userId,
            name: m.name,
            percentage: _round2((m.income / totalIncome) * 100),
            assignedAmount: _round2(billAmount * (m.income / totalIncome)),
          ),
        )
        .toList();

    return fixRounding(items, billAmount);
  }

  /// memberShare = billAmount / cantidad de miembros activos.
  static List<BillBreakdownItem> calculateEvenSplit(
    double billAmount,
    List<MemberIncomeProfile> members,
  ) {
    final active = members
        .where((m) => m.householdMemberId.isNotEmpty)
        .toList();
    if (active.isEmpty || billAmount <= 0) return const [];

    final share = billAmount / active.length;
    final pct = 100 / active.length;

    final items = active
        .map(
          (m) => BillBreakdownItem(
            householdMemberId: m.householdMemberId,
            userId: m.userId,
            name: m.name,
            percentage: _round2(pct),
            assignedAmount: _round2(share),
          ),
        )
        .toList();

    return fixRounding(items, billAmount);
  }

  /// Ajusta centavos en el último miembro para que la suma sea exacta.
  static List<BillBreakdownItem> fixRounding(
    List<BillBreakdownItem> items,
    double targetTotal,
  ) {
    if (items.isEmpty) return items;

    final sum = _round2(items.fold<double>(0, (s, i) => s + i.assignedAmount));
    final diff = _round2(targetTotal - sum);
    if (diff == 0) return items;

    final last = items.last;
    final adjusted = last.copyWith(
      assignedAmount: _round2(last.assignedAmount + diff),
    );
    return [...items.sublist(0, items.length - 1), adjusted];
  }

  static List<BillBreakdownItem> calculateSplit({
    required double billAmount,
    required EStrategy strategy,
    required List<MemberIncomeProfile> members,
  }) {
    return switch (strategy) {
      EStrategy.incomeBased =>
        calculateIncomeBasedSplit(billAmount, members),
      EStrategy.even => calculateEvenSplit(billAmount, members),
    };
  }

  static double totalIncome(List<MemberIncomeProfile> members) =>
      members.fold<double>(0, (sum, m) => sum + m.income);
}
