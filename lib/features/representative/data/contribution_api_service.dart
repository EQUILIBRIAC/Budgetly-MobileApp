import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';

class ContributionApiService {
  ContributionApiService(this._http);

  final HttpService _http;

  static Future<ContributionApiService> authorized() async {
    final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      http.setToken(token);
    }
    return ContributionApiService(http);
  }

  Future<List<ContributionDto>> getByHousehold(String householdId) async {
    final response =
        await _http.get(ApiPaths.contributionsByHousehold(householdId));
    return ApiJson.listDataFlexible(response)
        .map(ContributionDto.fromJson)
        .toList();
  }

  Future<ContributionDto?> getByBillId(String billId) async {
    try {
      final response = await _http.get(ApiPaths.contributionByBillId(billId));
      final rows = ApiJson.listDataFlexible(response);
      if (rows.isNotEmpty) {
        return ContributionDto.fromJson(rows.first);
      }
      final single = ApiJson.objectData(response);
      if (single != null) return ContributionDto.fromJson(single);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ContributionDto?> getById(String id) async {
    try {
      final response = await _http.get(ApiPaths.contributionById(id));
      final parsed = ApiJson.objectData(response);
      if (parsed == null) return null;
      return ContributionDto.fromJson(parsed);
    } catch (_) {
      return null;
    }
  }

  Future<ContributionDto> create({
    required String billId,
    required String householdId,
    required String description,
    required DateTime deadlineForMembers,
    required EStrategy strategy,
  }) async {
    final response = await _http.post(
      ApiPaths.contributionRoot,
      body: {
        'billId': billId,
        'householdId': householdId,
        'description': description,
        'deadlineForMembers': deadlineForMembers.toIso8601String(),
        'strategy': strategy.value,
      },
    );
    final parsed = ApiJson.objectData(response);
    if (parsed == null) {
      throw Exception('Respuesta inválida al crear contribución.');
    }
    return ContributionDto.fromJson(parsed);
  }

  Future<ContributionDto> update({
    required String id,
    required String description,
    required DateTime deadlineForMembers,
    required EStrategy strategy,
  }) async {
    final response = await _http.put(
      ApiPaths.contributionUpdate(id),
      body: {
        'description': description,
        'deadlineForMembers': deadlineForMembers.toIso8601String(),
        'strategy': strategy.value,
      },
    );
    final parsed = ApiJson.objectData(response);
    if (parsed == null) {
      throw Exception('Respuesta inválida al actualizar contribución.');
    }
    return ContributionDto.fromJson(parsed);
  }
}
