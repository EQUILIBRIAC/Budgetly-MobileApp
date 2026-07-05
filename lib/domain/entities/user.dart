import 'package:budgetly_app/core/utils/api_value_parsers.dart';

class User {
  final String id;
  final String email;
  final String role;
  final String householdId;
  final bool isNewUser;
  final String plan;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.householdId,
    required this.isNewUser,
    required this.plan,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: normalizeApiEmail(json['email']),
      role: json['role']?.toString().trim().toLowerCase() ?? 'unknown',
      householdId:
          json['householdId']?.toString() ?? json['houseHoldId']?.toString() ?? '',
      isNewUser: parseApiBool(json['isNewUser'], false),
      plan: json['plan']?.toString() ?? 'FREE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'householdId': householdId,
      'isNewUser': isNewUser,
      'plan': plan,
    };
  }
}
