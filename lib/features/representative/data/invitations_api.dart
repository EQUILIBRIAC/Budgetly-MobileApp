import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';

class InvitationsApi {
  InvitationsApi(this._http);

  final HttpService _http;

  static Future<InvitationsApi> authorized() async {
    final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      http.setToken(token);
    }
    return InvitationsApi(http);
  }

  Future<Map<String, dynamic>> create({
    required String email,
    required String householdId,
    String description = '',
  }) async {
    final response = await _http.post(
      ApiPaths.invitationsRoot,
      body: {
        'email': email.trim(),
        'householdId': householdId,
        'description': description.trim(),
      },
    );
    return ApiJson.objectData(response) ?? response;
  }

  Future<Map<String, dynamic>?> getPending({
    required String email,
    required String householdId,
  }) async {
    final response = await _http.get(
      ApiPaths.invitationsPending(
        email: email,
        householdId: householdId,
      ),
    );
    return ApiJson.objectData(response);
  }
}
