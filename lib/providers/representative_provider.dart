import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../models/contribution_model.dart';
import '../models/household_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';

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

  final householdId = user['householdId']?.toString() ?? '';
  if (householdId.isEmpty) {
    throw Exception('El representante no tiene householdId asignado.');
  }

  final http = HttpService(baseUrl: ApiConfig.baseUrl);
  final token = await StorageService.getToken();
  if (token != null && token.isNotEmpty) {
    http.setToken(token);
  }

  final responses = await Future.wait([
    http.get('/api/v1/household/$householdId'),
    http.get('/api/v1/household/$householdId/members'),
    http.get('/api/v1/household/$householdId/bills'),
    http.get('/api/v1/household/$householdId/contributions'),
  ]);

  final householdResponse = responses[0];
  final membersResponse = responses[1];
  final billsResponse = responses[2];
  final contributionsResponse = responses[3];

  final householdMap = _pickFirstMap(householdResponse);
  final household = householdMap == null ? null : Household.fromJson(householdMap);

  final members = _pickList(membersResponse)
      .map((json) => HouseholdMember.fromJson(json))
      .toList();
  final bills = _pickList(billsResponse).map((json) => Bill.fromJson(json)).toList();
  final contributions = _pickList(contributionsResponse)
      .map((json) => Contribution.fromJson(json))
      .toList();

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
    await http.post(
      '/api/v1/household/create',
      body: {
        'name': name.trim(),
        'description': description.trim(),
        'currency': currencyCode,
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
    await http.post(
      '/api/v1/household-member/create',
      body: {
        'householdId': householdId,
        'userId': userId,
        'role': role,
        if (income != null) 'income': income,
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
      '/api/v1/member-contributions/create',
      body: {
        'billId': billId,
        'householdId': householdId,
        'description': description.trim(),
        'deadlineForMembers':
            (deadlineForMembers ?? DateTime.now().add(const Duration(days: 15)))
                .toIso8601String(),
      },
    );
  }
}

final representativeActionsProvider = Provider<RepresentativeActions>((ref) {
  return RepresentativeActions();
});

Future<HttpService> _authorizedHttp() async {
  final http = HttpService(baseUrl: ApiConfig.baseUrl);
  final token = await StorageService.getToken();
  if (token != null && token.isNotEmpty) {
    http.setToken(token);
  }
  return http;
}

Map<String, dynamic>? _pickFirstMap(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
    return data.first as Map<String, dynamic>;
  }
  if (response.isNotEmpty) return response;
  return null;
}

List<Map<String, dynamic>> _pickList(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  if (response is List<Map<String, dynamic>>) return response;
  return const [];
}
