import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../models/contribution_model.dart';
import '../models/household_model.dart';
import '../models/settings_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';

final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = await StorageService.getUser();
  if (user == null) throw Exception('No hay sesión activa.');
  return user;
});

Future<HttpService> _authorizedHttp() async {
  final http = HttpService(baseUrl: ApiConfig.baseUrl);
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
    http.get('/api/v1/household/$householdId'),
    http.get('/api/v1/household/$householdId/members'),
    http.get('/api/v1/household/$householdId/bills'),
  ]);

  final householdRaw = responses[0]['data'];
  final membersRaw = responses[1]['data'];
  final billsRaw = responses[2]['data'];

  final household = householdRaw is Map<String, dynamic>
      ? Household.fromJson(householdRaw)
      : null;
  final members = membersRaw is List
      ? membersRaw
          .whereType<Map<String, dynamic>>()
          .map(HouseholdMember.fromJson)
          .toList()
      : <HouseholdMember>[];
  final bills = billsRaw is List
      ? billsRaw.whereType<Map<String, dynamic>>().map(Bill.fromJson).toList()
      : <Bill>[];

  return (household: household, members: members, bills: bills);
});

final memberContributionsProvider = FutureProvider<List<MemberContribution>>((
  ref,
) async {
  final http = await _authorizedHttp();
  final response = await http.get('/api/v1/member-contributions');
  final data = response['data'];
  if (data is! List) return <MemberContribution>[];
  return data
      .whereType<Map<String, dynamic>>()
      .map(MemberContribution.fromJson)
      .toList();
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
  final response = await http.get('/api/v1/household/search?query=$trimmed');
  final data = response['data'];
  if (data is! List) return <Household>[];
  return data.whereType<Map<String, dynamic>>().map(Household.fromJson).toList();
});

final settingsProvider = FutureProvider<UserSettings>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final userId = user['id']?.toString() ?? '';
  if (userId.isEmpty) throw Exception('Usuario inválido.');

  final http = await _authorizedHttp();
  final response = await http.get('/api/v1/settings/$userId');
  final data = response['data'];
  if (data is Map<String, dynamic>) {
    return UserSettings.fromJson(data);
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
