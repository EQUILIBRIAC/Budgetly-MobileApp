import 'package:budgetly_app/core/utils/api_value_parsers.dart';

class Household {
  final String id;
  final String name;
  final String description;
  final String currency;
  /// Miembros según el API (listado o detalle).
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Household({
    required this.id,
    required this.name,
    required this.description,
    required this.currency,
    this.memberCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Mi Hogar',
      description: json['description'] ?? '',
      currency: _currencyFromJson(json['currency']),
      memberCount: _parseCount(json['memberCount']),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static int _parseCount(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _currencyFromJson(dynamic v) {
    if (v == null) return 'PEN';
    if (v is String) {
      final u = v.toUpperCase();
      if (u == 'USD') return 'USD';
      return 'PEN';
    }
    if (v == 2) return 'USD';
    return 'PEN';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'currency': currency == 'USD' ? 2 : 1,
        'memberCount': memberCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Detalle de miembro (`GET .../household/{id}/detailed`); no incluye income.
class HouseholdMemberDetailed {
  final String householdMemberId;
  final String userId;
  final String? name;
  final String? email;
  final String? role;
  final String? status;
  final double totalContributed;
  final bool isRepresentative;
  final DateTime? joinedAt;

  HouseholdMemberDetailed({
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

  factory HouseholdMemberDetailed.fromJson(Map<String, dynamic> json) {
    return HouseholdMemberDetailed(
      householdMemberId: json['householdMemberId']?.toString() ??
          json['id']?.toString() ??
          '',
      userId: json['userId']?.toString() ?? '',
      name: _readPersonName(json),
      email: normalizeApiEmail(json['email']).isEmpty
          ? null
          : normalizeApiEmail(json['email']),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      totalContributed:
          HouseholdMember._parseDouble(json['totalContributed']) ?? 0,
      isRepresentative: json['isRepresentative'] == true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString())
          : null,
    );
  }

  static String? _readPersonName(Map<String, dynamic> json) {
    return extractPersonNameFromMap(json);
  }
}

/// Fila unificada para la pantalla de ingresos (miembros + detalle + income).
class MemberIncomeEntry {
  final String membershipId;
  final String userId;
  final String displayName;
  final String? email;
  final String? role;
  final String? status;
  final double income;
  final bool isRepresentative;

  const MemberIncomeEntry({
    required this.membershipId,
    required this.userId,
    required this.displayName,
    this.email,
    this.role,
    this.status,
    required this.income,
    this.isRepresentative = false,
  });

  MemberIncomeEntry copyWith({double? income}) => MemberIncomeEntry(
        membershipId: membershipId,
        userId: userId,
        displayName: displayName,
        email: email,
        role: role,
        status: status,
        income: income ?? this.income,
        isRepresentative: isRepresentative,
      );

  static List<MemberIncomeEntry> merge({
    required List<HouseholdMember> members,
    required List<HouseholdMemberDetailed> detailed,
    Map<String, String> userNamesById = const {},
    Map<String, String> userEmailsById = const {},
    Map<String, String> localNamesByUserId = const {},
    Map<String, String> signupNamesByEmail = const {},
  }) {
    final membersByUserId = {
      for (final m in members)
        if (m.userId.isNotEmpty) m.userId: m,
    };

    if (detailed.isNotEmpty) {
      final entries = detailed
          .where((d) => d.userId.isNotEmpty)
          .map((d) {
            final m = membersByUserId[d.userId];
            return MemberIncomeEntry(
              membershipId: d.householdMemberId.isNotEmpty
                  ? d.householdMemberId
                  : (m?.id ?? ''),
              userId: d.userId,
              displayName: _resolveDisplayName(
                detailed: d,
                member: m,
                profileName: userNamesById[d.userId],
                localName: localNamesByUserId[d.userId],
                signupName: _signupNameForUser(
                  detailedEmail: d.email,
                  userId: d.userId,
                  userEmailsById: userEmailsById,
                  signupNamesByEmail: signupNamesByEmail,
                ),
              ),
              email: _resolveEmail(
                detailedEmail: d.email,
                userId: d.userId,
                userEmailsById: userEmailsById,
              ),
              role: d.role ?? m?.role,
              status: d.status,
              income: m?.income ?? 0,
              isRepresentative: d.isRepresentative,
            );
          })
          .toList();
      entries.sort((a, b) => a.displayName.compareTo(b.displayName));
      return entries;
    }

    final entries = members.map((m) {
      return MemberIncomeEntry(
        membershipId: m.id,
        userId: m.userId,
        displayName: _resolveDisplayName(
          member: m,
          profileName: userNamesById[m.userId],
          localName: localNamesByUserId[m.userId],
          signupName: _signupNameForUser(
            userId: m.userId,
            userEmailsById: userEmailsById,
            signupNamesByEmail: signupNamesByEmail,
          ),
        ),
        email: _resolveEmail(
          userId: m.userId,
          userEmailsById: userEmailsById,
        ),
        role: m.role,
        status: null,
        income: m.income ?? 0,
        isRepresentative: false,
      );
    }).toList();

    entries.sort((a, b) => a.displayName.compareTo(b.displayName));
    return entries;
  }

  static String _resolveDisplayName({
    HouseholdMemberDetailed? detailed,
    HouseholdMember? member,
    String? profileName,
    String? localName,
    String? signupName,
  }) {
    for (final candidate in [
      detailed?.name,
      profileName,
      localName,
      signupName,
      member?.name,
    ]) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }

    final email = normalizeApiEmail(detailed?.email);
    if (email.contains('@')) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) return localPart;
    }

    return '';
  }

  static String? _resolveEmail({
    String? detailedEmail,
    required String userId,
    Map<String, String> userEmailsById = const {},
  }) {
    final fromDetailed = normalizeApiEmail(detailedEmail);
    if (fromDetailed.isNotEmpty) return fromDetailed;
    final fromDirectory = normalizeApiEmail(userEmailsById[userId]);
    return fromDirectory.isEmpty ? null : fromDirectory;
  }

  static String? _signupNameForUser({
    String? detailedEmail,
    required String userId,
    Map<String, String> userEmailsById = const {},
    Map<String, String> signupNamesByEmail = const {},
  }) {
    final email = _resolveEmail(
      detailedEmail: detailedEmail,
      userId: userId,
      userEmailsById: userEmailsById,
    );
    if (email == null || email.isEmpty) return null;
    return signupNamesByEmail[email.trim().toLowerCase()];
  }
}

class HouseholdMember {
  final String id;
  final String userId;
  final String householdId;
  final String? name;
  final double? income;
  final String? role;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  HouseholdMember({
    required this.id,
    required this.userId,
    required this.householdId,
    this.name,
    this.income,
    this.role,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    return HouseholdMember(
      id: json['id'] ?? '',
      userId: json['userId']?.toString() ?? '',
      householdId: json['householdId']?.toString() ??
          json['houseHoldId']?.toString() ??
          '',
      name: json['name'],
      income: _parseDouble(json['income']),
      role: json['role'],
      joinedAt:
          DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'householdId': householdId,
        'name': name,
        'income': income,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class Bill {
  final String id;
  final String householdId;
  final String description;
  final double amount;
  final String? category;
  final DateTime? paymentDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bill({
    required this.id,
    required this.householdId,
    required this.description,
    required this.amount,
    this.category,
    this.paymentDay,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] ?? '',
      householdId: json['householdId']?.toString() ??
          json['houseHoldId']?.toString() ??
          '',
      description: json['description'] ?? 'Gasto',
      amount: _parseDouble(json['amount']) ?? 0.0,
      category: json['category'] ?? json['categoryName'] ?? json['type'],
      paymentDay: json['paymentDay'] != null
          ? DateTime.tryParse(json['paymentDay'].toString())
          : json['paymentDate'] != null
              ? DateTime.tryParse(json['paymentDate'].toString())
              : null,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'householdId': householdId,
        'description': description,
        'amount': amount,
        'category': category,
        'paymentDay': paymentDay?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
