class Contribution {
  final String id;
  final String billId;
  final String householdId;
  final String? description;
  final DateTime deadlineForMembers;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contribution({
    required this.id,
    required this.billId,
    required this.householdId,
    this.description,
    required this.deadlineForMembers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] ?? '',
      billId: json['billId'] ?? '',
      householdId: json['householdId'] ?? '',
      description: json['description'],
      deadlineForMembers: DateTime.parse(
          json['deadlineForMembers'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'billId': billId,
        'householdId': householdId,
        'description': description,
        'deadlineForMembers': deadlineForMembers.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class MemberContribution {
  final String id;
  final String memberId;
  final String contributionId;
  final double amount;
  final int status;
  final DateTime? payedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemberContribution({
    required this.id,
    required this.memberId,
    required this.contributionId,
    required this.amount,
    required this.status,
    this.payedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemberContribution.fromJson(Map<String, dynamic> json) {
    return MemberContribution(
      id: json['id'] ?? '',
      memberId: json['memberId'] ?? '',
      contributionId: json['contributionId'] ?? '',
      amount: _parseDouble(json['amount']) ?? 0.0,
      status:
          json['status'] is bool ? (json['status'] ? 1 : 0) : (json['status'] ?? 0),
      payedAt: json['payedAt'] != null ? DateTime.parse(json['payedAt']) : null,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'contributionId': contributionId,
        'amount': amount,
        'status': status,
        'payedAt': payedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isPaid => status == 1;

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
