import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/network/network_exception.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';

class MemberContributionApiService {
  MemberContributionApiService(this._http);

  final HttpService _http;

  static Future<MemberContributionApiService> authorized() async {
    final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      http.setToken(token);
    }
    return MemberContributionApiService(http);
  }

  Future<List<MemberContributionDto>> getByContributionId(
    String contributionId,
  ) async {
    final response = await _http.get(
      ApiPaths.memberContributionsByContribution(contributionId),
    );
    return ApiJson.listDataFlexible(response)
        .map(MemberContributionDto.fromJson)
        .toList();
  }

  Future<MemberContributionDto> create({
    required String contributionId,
    required String memberId,
    required double amount,
  }) async {
    final response = await _http.post(
      ApiPaths.memberContributionRoot,
      body: {
        'contributionId': contributionId,
        'memberId': memberId,
        'amount': amount,
      },
    );
    final parsed = ApiJson.objectData(response);
    if (parsed == null) {
      throw Exception('Respuesta inválida al crear aporte de miembro.');
    }
    return MemberContributionDto.fromJson(parsed);
  }

  /// Marca aporte de miembro como pagado (`PUT .../mark-paid`).
  Future<MemberContributionDto> markAsPaid({
    required String memberContributionId,
    double? amount,
  }) async {
    try {
      final response = await _http.put(
        ApiPaths.memberContributionMarkPaid(memberContributionId),
        body: amount != null ? {'amount': amount} : {},
      );
      final parsed = ApiJson.objectData(response);
      if (parsed == null) {
        throw Exception('Respuesta inválida al marcar pago.');
      }
      return MemberContributionDto.fromJson(parsed);
    } on NetworkException catch (e) {
      if (e.statusCode == 404) {
        throw const MarkPaidEndpointMissingException();
      }
      rethrow;
    }
  }
}
