import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/utils/api_value_parsers.dart';

/// Perfil resumido desde `GET /api/v1/user`.
class UserDirectoryEntry {
  final String userId;
  final String email;
  final String? personName;
  final String houseHoldId;

  const UserDirectoryEntry({
    required this.userId,
    required this.email,
    this.personName,
    required this.houseHoldId,
  });
}

abstract final class UserDirectory {
  static Future<Map<String, UserDirectoryEntry>> fetchByUserId(
    HttpService http,
  ) async {
    try {
      final response = await http.get(ApiPaths.userList);
      final rows = ApiJson.listDataFlexible(response);
      final byId = <String, UserDirectoryEntry>{};
      for (final row in rows) {
        final uid = row['id']?.toString() ?? '';
        if (uid.isEmpty) continue;
        final email = normalizeApiEmail(row['email']);
        byId[uid] = UserDirectoryEntry(
          userId: uid,
          email: email,
          personName: extractPersonNameFromMap(row),
          houseHoldId: row['houseHoldId']?.toString() ??
              row['householdId']?.toString() ??
              '',
        );
      }
      return byId;
    } catch (_) {
      return {};
    }
  }

  static Map<String, UserDirectoryEntry> forHousehold(
    Map<String, UserDirectoryEntry> byUserId,
    String householdId,
  ) {
    final hid = householdId.trim();
    if (hid.isEmpty) return {};
    return {
      for (final entry in byUserId.values)
        if (entry.houseHoldId.trim() == hid) entry.userId: entry,
    };
  }

  static Map<String, String> namesByUserId(
    Map<String, UserDirectoryEntry> entries,
  ) {
    final names = <String, String>{};
    for (final entry in entries.values) {
      final parsed = entry.personName?.trim();
      if (parsed != null && parsed.isNotEmpty) {
        names[entry.userId] = parsed;
      }
    }
    return names;
  }

  static Map<String, String> emailsByUserId(
    Map<String, UserDirectoryEntry> entries,
  ) {
    return {
      for (final entry in entries.values)
        if (entry.email.isNotEmpty) entry.userId: entry.email,
    };
  }
}
