/// Rutas `/api/v1/...` alineadas al backend (controllers en snake_case).
/// Ver `gen-api-catalog.mjs` / `FLUTTER_ERROR_RED_CORRECCION.md`.
abstract final class ApiPaths {
  static String houseHold(String id) => '/api/v1/house_hold/$id';

  static String houseHoldsByRepresentative(String representativeId) =>
      '/api/v1/house_hold/representative/$representativeId';

  static const String houseHoldRoot = '/api/v1/house_hold';

  static String billsByHousehold(String householdId) =>
      '/api/v1/bills/byhousehold/$householdId';

  static const String billsRoot = '/api/v1/bills';

  static String billsUpdate(String id) => '/api/v1/bills/byid/$id';

  static String billsDelete(String id) => '/api/v1/bills/$id';

  static String houseHoldPut(String id) => '/api/v1/house_hold/$id';

  static String contributionUpdate(String id) => '/api/v1/contribution/byid/$id';

  static String contributionDelete(String id) => '/api/v1/contribution/$id';

  static String userDeleteByEmail(String email) =>
      '/api/v1/user/byemail/${Uri.encodeComponent(email)}';

  static String householdMembersByHousehold(String householdId) =>
      '/api/v1/household_member/household/$householdId';

  static String contributionsByHousehold(String householdId) =>
      '/api/v1/contribution/byhouseholdid/$householdId';

  static const String memberContributionRoot = '/api/v1/member_contribution';

  static String memberContributionsByMember(String memberId) =>
      '/api/v1/member_contribution/bymemberid/$memberId';

  static String householdMemberById(String id) => '/api/v1/household_member/$id';

  static const String householdMemberRoot = '/api/v1/household_member';

  static const String contributionRoot = '/api/v1/contribution';

  static String settingsByUserQuery(String userId) {
    final q = Uri.encodeQueryComponent(userId);
    return '/api/v1/settings?userId=$q';
  }

  static String settingsById(String id) => '/api/v1/settings/$id';

  static const String settingsRoot = '/api/v1/settings';
}

/// Desempaca respuestas con `data` o recurso en la raíz.
abstract final class ApiJson {
  static Map<String, dynamic>? objectData(Map<String, dynamic> response) {
    final d = response['data'];
    if (d is Map<String, dynamic>) return d;
    if (response.containsKey('id') ||
        response.containsKey('userId') ||
        response.containsKey('email') ||
        response.containsKey('language')) {
      return response;
    }
    return null;
  }

  static List<Map<String, dynamic>> listData(Map<String, dynamic> response) {
    final d = response['data'];
    if (d is List) {
      return d.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }
}
