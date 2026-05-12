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
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'representative',
      householdId: json['householdId'] as String? ?? '',
      isNewUser: json['isNewUser'] as bool? ?? false,
      plan: json['plan'] as String? ?? 'FREE',
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
