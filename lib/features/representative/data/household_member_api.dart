import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/network/user_directory.dart';
import 'package:budgetly_app/core/storage/member_display_name_store.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/member_view_model.dart';

class HouseholdMemberApi {
  HouseholdMemberApi(this._http);

  final HttpService _http;

  static Future<HouseholdMemberApi> authorized() async {
    final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      http.setToken(token);
    }
    return HouseholdMemberApi(http);
  }

  Future<List<MemberDetailedDto>> getDetailedMembers(String householdId) async {
    final response =
        await _http.get(ApiPaths.householdMembersDetailed(householdId));
    return ApiJson.listDataFlexible(response)
        .map(MemberDetailedDto.fromJson)
        .toList();
  }

  Future<List<HouseholdMemberDto>> getMembersWithIncome(String householdId) async {
    final response =
        await _http.get(ApiPaths.householdMembersByHousehold(householdId));
    return ApiJson.listDataFlexible(response)
        .map(HouseholdMemberDto.fromJson)
        .toList();
  }

  Future<HouseholdMemberDto> updateMemberIncome({
    required String householdMemberId,
    required double income,
  }) async {
    final response = await _http.put(
      ApiPaths.householdMemberById(householdMemberId),
      body: {
        'householdId': null,
        'userId': null,
        'isRepresentative': null,
        'income': income,
        'allocations': null,
      },
    );
    final parsed = ApiJson.objectData(response);
    if (parsed == null) {
      throw Exception('Respuesta inválida al guardar ingreso.');
    }
    return HouseholdMemberDto.fromJson(parsed);
  }

  Future<void> promoteRepresentative(String householdMemberId) async {
    await _http.put(ApiPaths.householdMemberPromote(householdMemberId), body: {});
  }

  Future<void> demoteRepresentative(String householdMemberId) async {
    await _http.put(ApiPaths.householdMemberDemote(householdMemberId), body: {});
  }

  /// Combina `/detailed` + `/household/{id}` por `userId`.
  Future<List<MemberViewModel>> getMergedMembers(String householdId) async {
    final detailed = await getDetailedMembers(householdId);
    final members = await getMembersWithIncome(householdId);

    final directory = await UserDirectory.fetchByUserId(_http);
    final householdUsers = UserDirectory.forHousehold(directory, householdId);
    final fallbackEmails = UserDirectory.emailsByUserId(householdUsers);
    final fallbackNames = {
      ...UserDirectory.namesByUserId(householdUsers),
      ...await MemberDisplayNameStore.loadByUserId(),
    };

    final signupByEmail = await MemberDisplayNameStore.loadByEmail();
    for (final entry in householdUsers.values) {
      final fromSignup = signupByEmail[entry.email.toLowerCase()];
      if (fromSignup != null && fromSignup.isNotEmpty) {
        fallbackNames[entry.userId] = fromSignup;
      }
    }

    return MemberViewModel.merge(
      detailed: detailed,
      members: members,
      fallbackNamesByUserId: fallbackNames,
      fallbackEmailsByUserId: fallbackEmails,
    );
  }
}
