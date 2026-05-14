class UserSettings {
  final String id;
  final String userId;
  final String language;
  final bool darkMode;
  final bool notificationEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    required this.language,
    required this.darkMode,
    required this.notificationEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      language: json['language'] ?? 'en',
      darkMode: json['darkMode'] ?? false,
      notificationEnabled: json['notificationEnabled'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'language': language,
        'darkMode': darkMode,
        'notificationEnabled': notificationEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserSettings copyWith({
    String? id,
    String? userId,
    String? language,
    bool? darkMode,
    bool? notificationEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
