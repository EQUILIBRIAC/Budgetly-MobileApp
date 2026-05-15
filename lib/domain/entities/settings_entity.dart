import 'package:budgetly_app/core/utils/api_value_parsers.dart';

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
    DateTime parseDt(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return UserSettings(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      language: normalizeLanguageCode(json['language'], 'es'),
      darkMode: parseApiBool(json['darkMode'], false),
      notificationEnabled: parseApiBool(json['notificationEnabled'], true),
      createdAt: parseDt(json['createdAt']),
      updatedAt: parseDt(json['updatedAt']),
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

  /// Cuerpo POST/PUT según catálogo API (sin enviar id vacío en creación).
  Map<String, dynamic> toApiBody() => {
        'userId': int.tryParse(userId) ?? userId,
        'language': language,
        'darkMode': darkMode,
        'notificationEnabled': notificationEnabled,
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
