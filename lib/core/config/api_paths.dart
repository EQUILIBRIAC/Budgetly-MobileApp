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

  static String userById(String id) => '/api/v1/user/user/$id';

  static String userUpdateByEmail(String email) =>
      '/api/v1/user/byemail/${Uri.encodeComponent(email)}';

  static const String userList = '/api/v1/user';

  static String householdMembersByHousehold(String householdId) =>
      '/api/v1/household_member/household/$householdId';

  static String householdMembersDetailed(String householdId) =>
      '/api/v1/household_member/household/$householdId/detailed';

  static String userIncomeByUserId(int userId) =>
      '/api/v1/user-income/byUserId/$userId';

  static String userIncomeById(String id) => '/api/v1/user-income/byId/$id';

  static const String userIncomeRoot = '/api/v1/user-income';

  static String incomeAllocationByHousehold(String householdId) =>
      '/api/v1/income_allocation/byHousehold/$householdId';

  static const String incomeAllocationRoot = '/api/v1/income_allocation';

  static String incomeAllocationById(String id) =>
      '/api/v1/income_allocation/byId/$id';

  static String contributionsByHousehold(String householdId) =>
      '/api/v1/contribution/byhouseholdid/$householdId';

  static String contributionByBillId(String billId) =>
      '/api/v1/contribution/bybillid/$billId';

  static String contributionById(String id) => '/api/v1/contribution/$id';

  static const String memberContributionRoot = '/api/v1/member_contribution';

  static String memberContributionsByContribution(String contributionId) =>
      '/api/v1/member_contribution/bycontributionid/$contributionId';

  static String memberContributionMarkPaid(String id) =>
      '/api/v1/member_contribution/byid/$id/mark-paid';

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

  /// Listas en `data`, raíz JSON array (vía HttpService) o claves habituales del API.
  static List<Map<String, dynamic>> listDataFlexible(
    Map<String, dynamic> response,
  ) {
    final fromData = listData(response);
    if (fromData.isNotEmpty) return fromData;

    for (final key in const [
      'value',
      'members',
      'householdMembers',
      'items',
      'results',
    ]) {
      final v = response[key];
      if (v is List) {
        return v.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }
}
