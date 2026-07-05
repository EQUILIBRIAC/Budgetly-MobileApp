import 'package:budgetly_app/core/utils/api_value_parsers.dart';

/// Sesión persistida tras sign-in / sign-up.
class AuthSession {
  final String userId;
  final String email;
  final String token;
  final String householdId;
  final String role;
  final String plan;
  final String householdMemberId;
  final bool isNewUser;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.token,
    required this.householdId,
    required this.role,
    required this.plan,
    this.householdMemberId = '',
    this.isNewUser = false,
  });

  String get roleNormalized => role.trim().toLowerCase();

  bool get isRepresentative =>
      roleNormalized == 'representative' || roleNormalized == 'admin';

  bool get isMember => roleNormalized == 'member';

  bool get isKnownRole => isRepresentative || isMember;

  bool get isPremium {
    final p = plan.trim().toLowerCase();
    return p.contains('premium') || p == '2';
  }

  bool get isFreePlan => !isPremium;

  AuthSession copyWith({
    String? householdId,
    String? householdMemberId,
    String? plan,
    String? role,
  }) {
    return AuthSession(
      userId: userId,
      email: email,
      token: token,
      householdId: householdId ?? this.householdId,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      householdMemberId: householdMemberId ?? this.householdMemberId,
      isNewUser: isNewUser,
    );
  }

  factory AuthSession.fromSignInJson(
    Map<String, dynamic> json, {
    required String token,
    String householdMemberId = '',
  }) {
    return AuthSession(
      userId: json['id']?.toString() ?? '',
      email: normalizeApiEmail(json['email']),
      token: token,
      householdId: json['householdId']?.toString() ??
          json['houseHoldId']?.toString() ??
          '',
      role: _normalizeRole(json['role']),
      plan: json['plan']?.toString() ?? 'Free',
      householdMemberId: householdMemberId,
      isNewUser: parseApiBool(json['isNewUser'], false),
    );
  }

  factory AuthSession.fromStoredJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      email: normalizeApiEmail(json['email']),
      token: json['token']?.toString() ?? '',
      householdId: json['householdId']?.toString() ?? '',
      role: _normalizeRole(json['role']),
      plan: json['plan']?.toString() ?? 'Free',
      householdMemberId: json['householdMemberId']?.toString() ?? '',
      isNewUser: parseApiBool(json['isNewUser'], false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': userId,
        'userId': userId,
        'email': email,
        'token': token,
        'householdId': householdId,
        'role': role,
        'plan': plan,
        'householdMemberId': householdMemberId,
        'isNewUser': isNewUser,
      };

  static String _normalizeRole(dynamic raw) {
    final s = raw?.toString().trim().toLowerCase() ?? '';
    if (s == 'member') return 'member';
    if (s == 'representative' || s == 'admin') return 'representative';
    return 'unknown';
  }
}
