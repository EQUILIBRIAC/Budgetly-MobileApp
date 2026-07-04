import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/member_view_model.dart';

/// Estrategia de reparto de gastos (backend `EStrategy`).
enum EStrategy {
  even(1),
  incomeBased(2);

  const EStrategy(this.value);
  final int value;

  static EStrategy fromInt(int? raw) {
    return switch (raw) {
      2 => EStrategy.incomeBased,
      _ => EStrategy.even,
    };
  }

  String get label => switch (this) {
        EStrategy.even => 'Even',
        EStrategy.incomeBased => 'IncomeBased',
      };

  String get labelEs => switch (this) {
        EStrategy.even => 'Reparto igualitario',
        EStrategy.incomeBased => 'Proporcional por ingreso',
      };
}

/// Factura del hogar (`GET /bills/byHousehold/{id}`).
class BillDto {
  final String id;
  final String householdId;
  final String description;
  final double amount;
  final DateTime? paymentDate;
  final int? createdBy;

  const BillDto({
    required this.id,
    required this.householdId,
    required this.description,
    required this.amount,
    this.paymentDate,
    this.createdBy,
  });

  factory BillDto.fromJson(Map<String, dynamic> json) {
    return BillDto(
      id: json['id']?.toString() ?? '',
      householdId: json['householdId']?.toString() ??
          json['houseHoldId']?.toString() ??
          '',
      description: json['description']?.toString() ?? 'Gasto',
      amount: _parseDouble(json['amount']) ?? 0,
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'].toString())
          : json['paymentDay'] != null
              ? DateTime.tryParse(json['paymentDay'].toString())
              : null,
      createdBy: json['createdBy'] is int
          ? json['createdBy'] as int
          : int.tryParse(json['createdBy']?.toString() ?? ''),
    );
  }

  factory BillDto.fromBill(Bill bill) => BillDto(
        id: bill.id,
        householdId: bill.householdId,
        description: bill.description,
        amount: bill.amount,
        paymentDate: bill.paymentDay,
      );

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Contribución vinculada a una factura.
class ContributionDto {
  final String id;
  final String billId;
  final String householdId;
  final String? description;
  final DateTime? deadlineForMembers;
  final EStrategy strategy;

  const ContributionDto({
    required this.id,
    required this.billId,
    required this.householdId,
    this.description,
    this.deadlineForMembers,
    this.strategy = EStrategy.even,
  });

  factory ContributionDto.fromJson(Map<String, dynamic> json) {
    final strategyRaw = json['strategy'];
    final strategyInt = strategyRaw is int
        ? strategyRaw
        : int.tryParse(strategyRaw?.toString() ?? '');

    return ContributionDto(
      id: json['id']?.toString() ?? '',
      billId: json['billId']?.toString() ?? '',
      householdId: json['householdId']?.toString() ??
          json['houseHoldId']?.toString() ??
          '',
      description: json['description']?.toString(),
      deadlineForMembers: json['deadlineForMembers'] != null
          ? DateTime.tryParse(json['deadlineForMembers'].toString())
          : null,
      strategy: EStrategy.fromInt(strategyInt),
    );
  }
}

/// Monto asignado a un miembro dentro de una contribución.
class MemberContributionDto {
  final String id;
  final String contributionId;
  final String memberId;
  final double amount;
  final String? status;
  final DateTime? payedAt;

  const MemberContributionDto({
    required this.id,
    required this.contributionId,
    required this.memberId,
    required this.amount,
    this.status,
    this.payedAt,
  });

  bool get isDone {
    final s = (status ?? '').toLowerCase();
    return s == 'done' || s == 'paid' || s == '1' || s == 'true';
  }

  bool get isPending => !isDone;

  factory MemberContributionDto.fromJson(Map<String, dynamic> json) {
    return MemberContributionDto(
      id: json['id']?.toString() ?? '',
      contributionId: json['contributionId']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      amount: _parseDouble(json['amount']) ?? 0,
      status: json['status']?.toString(),
      payedAt: _parsePayedAt(json['payedAt']),
    );
  }

  static DateTime? _parsePayedAt(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty || s.startsWith('01/01/0001')) return null;

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    final parts = s.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final mo = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && mo != null && y != null) {
        return DateTime(y, mo, d);
      }
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Perfil de ingreso de un miembro activo del hogar.
class MemberIncomeProfile {
  final String householdMemberId;
  final String userId;
  final String name;
  final double income;
  final double percentage;

  const MemberIncomeProfile({
    required this.householdMemberId,
    required this.userId,
    required this.name,
    required this.income,
    this.percentage = 0,
  });

  MemberIncomeProfile copyWith({
    String? householdMemberId,
    String? userId,
    String? name,
    double? income,
    double? percentage,
  }) {
    return MemberIncomeProfile(
      householdMemberId: householdMemberId ?? this.householdMemberId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      income: income ?? this.income,
      percentage: percentage ?? this.percentage,
    );
  }

  static List<MemberIncomeProfile> fromMemberViewModels(
    List<MemberViewModel> members,
  ) {
    return members
        .where((m) => m.userId.isNotEmpty && m.userId != '0')
        .map(
          (m) => MemberIncomeProfile(
            householdMemberId: m.householdMemberId,
            userId: m.userId,
            name: m.displayName,
            income: m.income,
          ),
        )
        .toList();
  }
}

/// Línea del desglose por miembro.
class BillBreakdownItem {
  final String householdMemberId;
  final String userId;
  final String name;
  final double percentage;
  final double assignedAmount;

  const BillBreakdownItem({
    required this.householdMemberId,
    required this.userId,
    required this.name,
    required this.percentage,
    required this.assignedAmount,
  });

  BillBreakdownItem copyWith({
    String? householdMemberId,
    String? userId,
    String? name,
    double? percentage,
    double? assignedAmount,
  }) {
    return BillBreakdownItem(
      householdMemberId: householdMemberId ?? this.householdMemberId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      assignedAmount: assignedAmount ?? this.assignedAmount,
    );
  }
}

/// Contribución enriquecida para la pantalla de Aportes.
class ContributionOverviewItem {
  final String contributionId;
  final String billId;
  final String? description;
  final DateTime deadlineForMembers;
  final EStrategy strategy;
  final double billAmount;
  final String? billDescription;
  final List<BillBreakdownItem> memberShares;

  const ContributionOverviewItem({
    required this.contributionId,
    required this.billId,
    this.description,
    required this.deadlineForMembers,
    required this.strategy,
    required this.billAmount,
    this.billDescription,
    required this.memberShares,
  });

  double get totalAssigned =>
      memberShares.fold(0, (sum, item) => sum + item.assignedAmount);
}

/// Vista unificada para pantalla de detalle de factura.
class BillBreakdownViewModel {
  final BillDto bill;
  final ContributionDto contribution;
  final EStrategy strategy;
  final List<BillBreakdownItem> items;

  const BillBreakdownViewModel({
    required this.bill,
    required this.contribution,
    required this.strategy,
    required this.items,
  });

  double get totalAssigned =>
      items.fold(0, (sum, item) => sum + item.assignedAmount);

  bool get totalsMatch =>
      (totalAssigned - bill.amount).abs() < 0.01;
}

/// Porcentaje de ingreso persistido opcionalmente.
class IncomeAllocationDto {
  final String id;
  final int userId;
  final String householdId;
  final double percentage;

  const IncomeAllocationDto({
    required this.id,
    required this.userId,
    required this.householdId,
    required this.percentage,
  });

  factory IncomeAllocationDto.fromJson(Map<String, dynamic> json) {
    return IncomeAllocationDto(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      householdId: json['householdId']?.toString() ?? '',
      percentage: _parseDouble(json['percentage']) ?? 0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
