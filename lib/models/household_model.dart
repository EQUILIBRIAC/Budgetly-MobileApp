class Household {
  final String id;
  final String name;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Household({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Mi Hogar',
      currency: json['currency'] == 2 ? 'USD' : 'PEN',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'currency': currency == 'USD' ? 2 : 1,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
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
      userId: json['userId'] ?? '',
      householdId: json['householdId'] ?? '',
      name: json['name'],
      income: _parseDouble(json['income']),
      role: json['role'],
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
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
      householdId: json['householdId'] ?? '',
      description: json['description'] ?? 'Gasto',
      amount: _parseDouble(json['amount']) ?? 0.0,
      category: json['category'] ?? json['categoryName'] ?? json['type'],
      paymentDay: json['paymentDay'] != null ? DateTime.parse(json['paymentDay']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
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
