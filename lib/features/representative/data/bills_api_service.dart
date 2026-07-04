import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';

class BillsApiService {
  BillsApiService(this._http);

  final HttpService _http;

  static Future<BillsApiService> authorized() async {
    final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      http.setToken(token);
    }
    return BillsApiService(http);
  }

  Future<List<BillDto>> getByHousehold(String householdId) async {
    final response = await _http.get(ApiPaths.billsByHousehold(householdId));
    return ApiJson.listDataFlexible(response)
        .map(BillDto.fromJson)
        .toList();
  }
}
