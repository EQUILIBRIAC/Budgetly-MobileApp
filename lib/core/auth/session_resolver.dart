import '../config/api_paths.dart';
import '../network/http_service.dart';
abstract final class SessionResolver {
  static Future<String?> resolveHouseholdMemberId({
    required HttpService http,
    required String userId,
    required String householdId,
  }) async {
    final uid = userId.trim();
    final hid = householdId.trim();
    if (uid.isEmpty || hid.isEmpty) return null;

    try {
      final response =
          await http.get(ApiPaths.householdMembersByHousehold(hid));
      final list = ApiJson.listDataFlexible(response);
      for (final row in list) {
        if (row['userId']?.toString() == uid) {
          final id = row['id']?.toString().trim() ?? '';
          if (id.isNotEmpty) return id;
        }
      }
    } catch (_) {}
    return null;
  }
}
