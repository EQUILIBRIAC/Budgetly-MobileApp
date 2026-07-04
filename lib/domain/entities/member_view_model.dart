import 'package:budgetly_app/core/utils/api_value_parsers.dart';

/// `GET .../household/{id}/detailed`
class MemberDetailedDto {
  final String householdMemberId;
  final String userId;
  final String? name;
  final String? email;
  final String? role;
  final String? status;
  final double totalContributed;
  final bool isRepresentative;
  final DateTime? joinedAt;

  const MemberDetailedDto({
    required this.householdMemberId,
    required this.userId,
    this.name,
    this.email,
    this.role,
    this.status,
    this.totalContributed = 0,
    this.isRepresentative = false,
    this.joinedAt,
  });

  factory MemberDetailedDto.fromJson(Map<String, dynamic> json) {
    return MemberDetailedDto(
      householdMemberId: json['householdMemberId']?.toString() ??
          json['id']?.toString() ??
          '',
      userId: json['userId']?.toString() ?? '',
      name: extractPersonNameFromMap(json),
      email: _email(json['email']),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      totalContributed: _parseDouble(json['totalContributed']) ?? 0,
      isRepresentative: json['isRepresentative'] == true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
    );
  }

  static String? _email(dynamic raw) {
    final parsed = normalizeApiEmail(raw);
    return parsed.isEmpty ? null : parsed;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// `GET .../household/{id}` (incluye income).
class HouseholdMemberDto {
  final String id;
  final String householdId;
  final String userId;
  final double income;
  final bool isRepresentative;
  final DateTime? joinedAt;

  const HouseholdMemberDto({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.income,
    this.isRepresentative = false,
    this.joinedAt,
  });

  factory HouseholdMemberDto.fromJson(Map<String, dynamic> json) {
    return HouseholdMemberDto(
      id: json['id']?.toString() ?? '',
      householdId: json['householdId']?.toString() ??
          json['houseHoldId']?.toString() ??
          '',
      userId: json['userId']?.toString() ?? '',
      income: _parseDouble(json['income']) ?? 0,
      isRepresentative: json['isRepresentative'] == true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
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

/// Modelo unificado para UI (Miembros + Ingresos).
class MemberViewModel {
  final String householdMemberId;
  final String userId;
  final String displayName;
  final String? email;
  final String? role;
  final String? status;
  final double income;
  final bool isRepresentative;
  final double totalContributed;

  const MemberViewModel({
    required this.householdMemberId,
    required this.userId,
    required this.displayName,
    this.email,
    this.role,
    this.status,
    required this.income,
    this.isRepresentative = false,
    this.totalContributed = 0,
  });

  /// name → email → "Sin nombre"
  static String resolveDisplayName({
    String? name,
    String? email,
    String? fallbackName,
  }) {
    for (final candidate in [name, fallbackName]) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    final parsedEmail = normalizeApiEmail(email);
    if (parsedEmail.isNotEmpty) return parsedEmail;
    return 'Sin nombre';
  }

  static List<MemberViewModel> merge({
    required List<MemberDetailedDto> detailed,
    required List<HouseholdMemberDto> members,
    Map<String, String> fallbackNamesByUserId = const {},
    Map<String, String> fallbackEmailsByUserId = const {},
  }) {
    final incomeByUserId = {
      for (final m in members)
        if (m.userId.isNotEmpty) m.userId: m,
    };

    if (detailed.isNotEmpty) {
      final rows = detailed.where((d) => d.userId.isNotEmpty).map((d) {
        final incomeRow = incomeByUserId[d.userId];
        final email = d.email ?? fallbackEmailsByUserId[d.userId];
        return MemberViewModel(
          householdMemberId: d.householdMemberId.isNotEmpty
              ? d.householdMemberId
              : (incomeRow?.id ?? ''),
          userId: d.userId,
          displayName: resolveDisplayName(
            name: d.name,
            email: email,
            fallbackName: fallbackNamesByUserId[d.userId],
          ),
          email: email,
          role: d.role,
          status: d.status,
          income: incomeRow?.income ?? 0,
          isRepresentative: d.isRepresentative,
          totalContributed: d.totalContributed,
        );
      }).toList();
      rows.sort((a, b) => a.displayName.compareTo(b.displayName));
      return rows;
    }

    final rows = members.map((m) {
      final email = fallbackEmailsByUserId[m.userId];
      return MemberViewModel(
        householdMemberId: m.id,
        userId: m.userId,
        displayName: resolveDisplayName(
          email: email,
          fallbackName: fallbackNamesByUserId[m.userId],
        ),
        email: email,
        role: null,
        status: null,
        income: m.income,
        isRepresentative: m.isRepresentative,
      );
    }).toList();
    rows.sort((a, b) => a.displayName.compareTo(b.displayName));
    return rows;
  }

  String get roleLabel {
    if (isRepresentative) return 'Representante';
    return switch ((role ?? '').toLowerCase()) {
      'member' => 'Miembro',
      'representative' => 'Representante',
      'admin' => 'Administrador',
      _ => role?.isNotEmpty == true ? role! : 'Miembro',
    };
  }
}
