import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';

class IncomeAllocationApiService {
  IncomeAllocationApiService(this._http);

  final HttpService _http;

  static Future<IncomeAllocationApiService> authorized() async {
    final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      http.setToken(token);
    }
    return IncomeAllocationApiService(http);
  }

  Future<List<IncomeAllocationDto>> getByHousehold(String householdId) async {
    try {
      final response =
          await _http.get(ApiPaths.incomeAllocationByHousehold(householdId));
      return ApiJson.listDataFlexible(response)
          .map(IncomeAllocationDto.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> create({
    required int userId,
    required String householdId,
    required double percentage,
  }) async {
    await _http.post(
      ApiPaths.incomeAllocationRoot,
      body: {
        'userId': userId,
        'householdId': householdId,
        'percentage': percentage,
      },
    );
  }
}
