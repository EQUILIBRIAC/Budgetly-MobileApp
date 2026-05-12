/// Configuración de API y ambiente
/// Este archivo centraliza todas las URLs y constantes de configuración
/// para que no estén esparcidas por toda la aplicación

class ApiConfig {
  /// URL base del API según el ambiente
  /// 
  /// Para desarrollo local (Android Emulator):
  /// http://10.0.2.2:5070
  /// 
  /// Para desarrollo local (iOS Simulator):
  /// http://localhost:5070
  /// 
  /// Para producción:
  /// https://api.tudominio.com
  static const String baseUrl = 'http://10.0.2.2:5070';

  // ============ AUTENTICACIÓN ============
  static const String signIn = '$baseUrl/api/v1/authentication/sign-in';
  static const String signUp = '$baseUrl/api/v1/authentication/sign-up';
  static const String forgotPassword =
      '$baseUrl/api/v1/authentication/forgot-password';
  static const String refreshToken =
      '$baseUrl/api/v1/authentication/refresh-token';

  // ============ USUARIO ============
  static String getUserProfile(String userId) =>
      '$baseUrl/api/v1/user/user/$userId';

  static const String updateProfile = '$baseUrl/api/v1/user/update';

  // ============ HOGAR ============
  static String getHousehold(String householdId) =>
      '$baseUrl/api/v1/household/$householdId';

  static String getHouseholdMembers(String householdId) =>
      '$baseUrl/api/v1/household/$householdId/members';

  static String getHouseholdBills(String householdId) =>
      '$baseUrl/api/v1/household/$householdId/bills';

  static String getHouseholdContributions(String householdId) =>
      '$baseUrl/api/v1/household/$householdId/contributions';

  static const String searchHousehold = '$baseUrl/api/v1/household/search';
  static const String createHousehold = '$baseUrl/api/v1/household/create';
  static const String joinHousehold = '$baseUrl/api/v1/household/join';

  // ============ MIEMBRO DEL HOGAR ============
  static String updateHouseholdMember(String memberId) =>
      '$baseUrl/api/v1/household-member/$memberId';

  static const String createHouseholdMember =
      '$baseUrl/api/v1/household-member/create';

  static const String getHouseholdMembers_raw =
      '$baseUrl/api/v1/household-member';

  // ============ CONTRIBUCIONES ============
  static const String memberContributions =
      '$baseUrl/api/v1/member-contributions';

  static String getMemberContributions(String memberId) =>
      '$baseUrl/api/v1/member-contributions?memberId=$memberId';

  static String getContributionsByContribution(String contributionId) =>
      '$baseUrl/api/v1/member-contributions?contributionId=$contributionId';

  static const String createContribution =
      '$baseUrl/api/v1/member-contributions/create';

  static String updateContribution(String id) =>
      '$baseUrl/api/v1/member-contributions/$id';

  // ============ CONFIGURACIÓN ============
  static const String userSettings = '$baseUrl/api/v1/settings';
  static String updateSettings(String userId) =>
      '$baseUrl/api/v1/settings/$userId';

  // ============ TIMEOUTS ============
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ============ HEADERS PREDETERMINADOS ============
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

/// Información del Ambiente
class EnvironmentInfo {
  static const String name = 'development'; // development, staging, production
  static const bool isProduction = false;
  static const bool isDevelopment = true;
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
}
