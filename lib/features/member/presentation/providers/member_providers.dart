import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/settings_entity.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';

final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = await StorageService.getUser();
  if (user == null) throw Exception('No hay sesión activa.');
  return user;
});

Future<HttpService> _authorizedHttp() async {
  final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
  final token = await StorageService.getToken();
  if (token != null && token.isNotEmpty) {
    http.setToken(token);
  }
  return http;
}

final memberDashboardProvider = FutureProvider<({
  Household? household,
  List<HouseholdMember> members,
  List<Bill> bills,
})>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final householdId = user['householdId']?.toString() ?? '';
  if (householdId.isEmpty) throw Exception('No hay hogar asignado.');

  final http = await _authorizedHttp();
  final responses = await Future.wait([
    http.get(ApiPaths.houseHold(householdId)),
    http.get(ApiPaths.householdMembersByHousehold(householdId)),
    http.get(ApiPaths.billsByHousehold(householdId)),
  ]);

  final householdRaw = ApiJson.objectData(responses[0]);
  final household =
      householdRaw == null ? null : Household.fromJson(householdRaw);

  final members = ApiJson.listData(responses[1])
      .map(HouseholdMember.fromJson)
      .toList();
  final bills =
      ApiJson.listData(responses[2]).map(Bill.fromJson).toList();

  return (household: household, members: members, bills: bills);
});

final memberContributionsProvider = FutureProvider<List<MemberContribution>>((
  ref,
) async {
  final http = await _authorizedHttp();
  final response = await http.get(ApiPaths.memberContributionRoot);
  final data = ApiJson.listData(response);
  return data.map(MemberContribution.fromJson).toList();
});

final householdStatusProvider = FutureProvider<({
  Household? household,
  List<HouseholdMember> members,
  List<Bill> bills,
})>((ref) async {
  return ref.watch(memberDashboardProvider.future);
});

final searchHouseholdProvider = FutureProvider.family<List<Household>, String>((
  ref,
  query,
) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return <Household>[];
  final http = await _authorizedHttp();
  final response = await http.get(ApiPaths.houseHold(trimmed));
  final raw = ApiJson.objectData(response);
  if (raw == null) return <Household>[];
  return [Household.fromJson(raw)];
});

final settingsProvider = FutureProvider<UserSettings>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final userId = user['id']?.toString() ?? '';
  if (userId.isEmpty) throw Exception('Usuario inválido.');

  final http = await _authorizedHttp();
  final response = await http.get(ApiPaths.settingsByUserQuery(userId));
  final parsed = ApiJson.objectData(response);
  if (parsed != null) {
    return UserSettings.fromJson(parsed);
  }
  return UserSettings(
    id: '',
    userId: userId,
    language: 'es',
    darkMode: false,
    notificationEnabled: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
});
