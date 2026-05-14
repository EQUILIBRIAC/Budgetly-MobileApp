import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';

class RepresentativeData {
  final Household? household;
  final List<HouseholdMember> members;
  final List<Bill> bills;
  final List<Contribution> contributions;
  final String currency;

  const RepresentativeData({
    required this.household,
    required this.members,
    required this.bills,
    required this.contributions,
    required this.currency,
  });

  double get totalBills => bills.fold(0, (sum, b) => sum + b.amount);
  int get overdueBills =>
      bills.where((b) => b.paymentDay != null && b.paymentDay!.isBefore(DateTime.now())).length;
}

final representativeProvider = FutureProvider<RepresentativeData>((ref) async {
  final user = await StorageService.getUser();
  if (user == null) {
    throw Exception('No se encontró sesión de usuario.');
  }

  final repId = user['id']?.toString() ?? '';
  if (repId.isEmpty) {
    throw Exception('Sesión sin id de usuario.');
  }

  final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
  final token = await StorageService.getToken();
  if (token != null && token.isNotEmpty) {
    http.setToken(token);
  }

  final ownedResp = await http.get(ApiPaths.houseHoldsByRepresentative(repId));
  final owned = ApiJson.listData(ownedResp);

  var householdId = user['householdId']?.toString().trim() ?? '';
  if (householdId.isEmpty && owned.isNotEmpty) {
    householdId = owned.first['id']?.toString() ?? '';
  }

  if (householdId.isEmpty) {
    throw Exception(
      'No hay hogar para mostrar. Crea uno en «Hogares» o completa tu perfil.',
    );
  }

  final responses = await Future.wait([
    http.get(ApiPaths.houseHold(householdId)),
    http.get(ApiPaths.householdMembersByHousehold(householdId)),
    http.get(ApiPaths.billsByHousehold(householdId)),
    http.get(ApiPaths.contributionsByHousehold(householdId)),
  ]);

  final householdMap = _pickFirstMap(responses[0]);
  final household =
      householdMap == null ? null : Household.fromJson(householdMap);

  final members = _pickList(responses[1]).map(HouseholdMember.fromJson).toList();
  final bills = _pickList(responses[2]).map(Bill.fromJson).toList();
  final contributions =
      _pickList(responses[3]).map(Contribution.fromJson).toList();

  return RepresentativeData(
    household: household,
    members: members,
    bills: bills,
    contributions: contributions,
    currency: household?.currency ?? 'PEN',
  );
});

class RepresentativeActions {
  Future<void> createHousehold({
    required String name,
    String description = '',
    int currencyCode = 1,
  }) async {
    final http = await _authorizedHttp();
    final user = await StorageService.getUser();
    final repId = int.tryParse(user?['id']?.toString() ?? '') ?? 0;
    await http.post(
      ApiPaths.houseHoldRoot,
      body: {
        'id': null,
        'name': name.trim(),
        'representativeId': repId,
        'currency': currencyCode == 2 ? 'USD' : 'PEN',
        'description': description.trim().isEmpty ? null : description.trim(),
        'memberCount': null,
        'startDate': null,
        'createdAt': null,
        'updatedAt': null,
      },
    );
  }

  Future<void> createMember({
    required String householdId,
    required String userId,
    String role = 'member',
    double? income,
  }) async {
    final http = await _authorizedHttp();
    final uid = int.tryParse(userId.trim());
    if (uid == null) {
      throw FormatException('El User ID debe ser numérico para la API.');
    }
    await http.post(
      ApiPaths.householdMemberRoot,
      body: {
        'householdId': householdId,
        'userId': uid,
        'isRepresentative': role.toLowerCase() == 'representative',
        'income': income ?? 0,
      },
    );
  }

  Future<void> createContribution({
    required String billId,
    required String householdId,
    String description = '',
    DateTime? deadlineForMembers,
  }) async {
    final http = await _authorizedHttp();
    await http.post(
      ApiPaths.contributionRoot,
      body: {
        'billId': billId,
        'householdId': householdId,
        'description': description.trim(),
        'deadlineForMembers':
            (deadlineForMembers ?? DateTime.now().add(const Duration(days: 15)))
                .toIso8601String(),
        'strategy': null,
      },
    );
  }
}

final representativeActionsProvider = Provider<RepresentativeActions>((ref) {
  return RepresentativeActions();
});

Future<HttpService> _authorizedHttp() async {
  final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
  final token = await StorageService.getToken();
  if (token != null && token.isNotEmpty) {
    http.setToken(token);
  }
  return http;
}

Map<String, dynamic>? _pickFirstMap(Map<String, dynamic> response) {
  final o = ApiJson.objectData(response);
  if (o != null) return o;
  final list = ApiJson.listData(response);
  if (list.isNotEmpty) return list.first;
  return null;
}

List<Map<String, dynamic>> _pickList(Map<String, dynamic> response) {
  final list = ApiJson.listData(response);
  if (list.isNotEmpty) return list;
  final o = ApiJson.objectData(response);
  return o == null ? const [] : [o];
}
