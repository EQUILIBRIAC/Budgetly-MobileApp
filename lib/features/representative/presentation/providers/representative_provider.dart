import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/core/auth/app_permissions.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/features/representative/data/invitations_api.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/member_display_name_store.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';

class RepresentativeData {
  final Household? household;
  /// Hogares que posee el representante (respuesta de `/house_hold/representative/...`).
  final List<Household> ownedHouseholds;
  /// ID del hogar con el que se cargaron facturas, miembros y detalle.
  final String activeHouseholdId;
  final List<HouseholdMember> members;
  final List<Bill> bills;
  final List<Contribution> contributions;
  final String currency;

  const RepresentativeData({
    required this.household,
    required this.ownedHouseholds,
    required this.activeHouseholdId,
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
  final ownedIds = owned
      .map((e) => e['id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();

  var householdId = user['householdId']?.toString().trim() ?? '';
  // Si el ID en sesión ya no existe en los hogares del representante (borrado,
  // cuenta antigua o dato viejo en prefs), el detalle `/house_hold/:id` devuelve 404.
  if (owned.isNotEmpty &&
      (householdId.isEmpty || !ownedIds.contains(householdId))) {
    householdId = owned.first['id']?.toString() ?? '';
  }

  if (householdId.isEmpty) {
    return const RepresentativeData(
      household: null,
      ownedHouseholds: [],
      activeHouseholdId: '',
      members: [],
      bills: [],
      contributions: [],
      currency: 'PEN',
    );
  }

  final ownedHouseholds = <Household>[];
  for (final row in owned) {
    try {
      ownedHouseholds.add(Household.fromJson(row));
    } catch (_) {
      // El listado del representante puede traer campos mínimos; ignorar filas raras.
    }
  }

  final storedHid = user['householdId']?.toString().trim() ?? '';
  if (storedHid != householdId) {
    final updated = Map<String, dynamic>.from(user);
    updated['householdId'] = householdId;
    await StorageService.saveUser(updated);
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
    ownedHouseholds: ownedHouseholds,
    activeHouseholdId: householdId,
    members: members,
    bills: bills,
    contributions: contributions,
    currency: household?.currency ?? 'PEN',
  );
});

/// Evita invalidar el [representativeProvider] en medio del desmontaje de un
/// modal o route overlay: mover el refresco al frame siguiente elimina asserts
/// del estilo `_dependents.isEmpty` en debug.
void scheduleRepresentativeProviderRefresh(WidgetRef ref) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.invalidate(representativeProvider);
  });
}

class RepresentativeActions {
  Future<void> createHousehold({
    required String name,
    String description = '',
    int currencyCode = 1,
    required int ownedHouseholdCount,
    required bool isPremiumPlan,
  }) async {
    final perms = AppPermissions('representative');
    if (!perms.canCreateAnotherHousehold(
      ownedHouseholdCount: ownedHouseholdCount,
      isPremiumPlan: isPremiumPlan,
    )) {
      throw Exception(
        isPremiumPlan
            ? 'No puedes crear más hogares.'
            : 'Plan Free: solo puedes tener 1 hogar. Actualiza a Premium para más.',
      );
    }
    final http = await _authorizedHttp();
    final user = await StorageService.getUser();
    final repId = int.tryParse(user?['id']?.toString() ?? '') ?? 0;
    final response = await http.post(
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
    final created = ApiJson.objectData(response) ?? response;
    final newId = created['id']?.toString().trim() ?? '';
    if (newId.isNotEmpty && user != null) {
      final updated = Map<String, dynamic>.from(user);
      updated['householdId'] = newId;
      await StorageService.saveUser(updated);
    }
  }

  Future<void> createBill({
    required String householdId,
    required String description,
    required double amount,
    required int createdBy,
    DateTime? paymentDate,
  }) async {
    final http = await _authorizedHttp();
    await http.post(
      ApiPaths.billsRoot,
      body: {
        'houseHoldId': householdId,
        'description': description.trim(),
        'amount': amount,
        'createdBy': createdBy,
        'paymentDate': (paymentDate ??
                DateTime.now().add(const Duration(days: 30)))
            .toIso8601String(),
      },
    );
  }

  Future<void> createMember({
    required String householdId,
    required String userId,
    String role = 'member',
    double? income,
    required int currentMemberCount,
    required bool isPremiumPlan,
  }) async {
    final perms = AppPermissions('representative');
    if (!perms.canAddAnotherMember(
      currentMemberCount: currentMemberCount,
      isPremiumPlan: isPremiumPlan,
    )) {
      throw Exception(
        'Plan Free: máximo 3 miembros por hogar. Actualiza a Premium para más.',
      );
    }
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

  /// Actualiza ingreso mensual vía `PUT /household_member/{id}` (sincroniza UserIncome).
  Future<HouseholdMember> updateMemberIncome({
    required String membershipId,
    required double income,
  }) async {
    final http = await _authorizedHttp();
    final response = await http.put(
      ApiPaths.householdMemberById(membershipId),
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
    return HouseholdMember.fromJson(parsed);
  }

  /// Guarda nombre visible localmente y lo sincroniza con el perfil del API si hay email.
  Future<void> saveMemberDisplayName({
    required String userId,
    required String name,
    String? email,
  }) async {
    final trimmed = name.trim();
    if (userId.trim().isEmpty || trimmed.isEmpty) return;

    await MemberDisplayNameStore.saveForUserId(userId, trimmed);
    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) {
      await MemberDisplayNameStore.saveForEmail(normalizedEmail, trimmed);
      try {
        await updateUserPersonName(
          email: normalizedEmail,
          personName: trimmed,
        );
      } catch (_) {}
    }
  }

  Future<void> updateUserPersonName({
    required String email,
    required String personName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = personName.trim();
    if (normalizedEmail.isEmpty || trimmedName.isEmpty) return;

    final http = await _authorizedHttp();
    await http.put(
      ApiPaths.userUpdateByEmail(normalizedEmail),
      body: {
        'emailAddress': normalizedEmail,
        'personName': trimmedName,
        'password': '',
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

  Future<void> updateContribution({
    required String id,
    String? description,
    DateTime? deadlineForMembers,
  }) async {
    final http = await _authorizedHttp();
    await http.put(
      ApiPaths.contributionUpdate(id),
      body: {
        'description': description,
        'deadlineForMembers': deadlineForMembers?.toIso8601String(),
        'strategy': null,
      },
    );
  }

  Future<void> deleteContribution(String id) async {
    final http = await _authorizedHttp();
    await http.delete(ApiPaths.contributionDelete(id));
  }

  Future<void> updateHousehold({
    required String id,
    required String name,
    required String description,
    required int memberCount,
    required String currencyCode, // "PEN" | "USD"
    DateTime? startDate,
  }) async {
    final http = await _authorizedHttp();
    await http.put(
      ApiPaths.houseHoldPut(id),
      body: {
        'name': name.trim(),
        'description': description.trim(),
        'memberCount': memberCount,
        'currency': currencyCode,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
      },
    );
  }

  Future<void> setPreferredHousehold(String householdId) async {
    final user = await StorageService.getUser();
    if (user == null) throw Exception('Sin sesión.');
    final repId = user['id']?.toString() ?? '';
    if (repId.isEmpty) throw Exception('Usuario inválido.');
    final http = await _authorizedHttp();
    final ownedResp = await http.get(ApiPaths.houseHoldsByRepresentative(repId));
    final owned = ApiJson.listData(ownedResp);
    final ids = owned
        .map((e) => e['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    if (!ids.contains(householdId)) {
      throw Exception('Ese hogar no está en tu lista de representante.');
    }
    final updated = Map<String, dynamic>.from(user);
    updated['householdId'] = householdId;
    await StorageService.saveUser(updated);
  }

  Future<void> updateBill({
    required String id,
    String? description,
    double? amount,
    DateTime? paymentDate,
  }) async {
    final http = await _authorizedHttp();
    await http.put(
      ApiPaths.billsUpdate(id),
      body: {
        'description': description,
        'amount': amount,
        'paymentDate': paymentDate?.toIso8601String(),
      },
    );
  }

  Future<void> deleteBill(String id) async {
    final http = await _authorizedHttp();
    await http.delete(ApiPaths.billsDelete(id));
  }

  Future<void> deleteHouseholdMember(String membershipId) async {
    final http = await _authorizedHttp();
    await http.delete(ApiPaths.householdMemberById(membershipId));
  }

  Future<Map<String, dynamic>> sendInvitation({
    required String email,
    required String householdId,
    String description = '',
  }) async {
    final api = InvitationsApi(await _authorizedHttp());
    return api.create(
      email: email,
      householdId: householdId,
      description: description,
    );
  }

  Future<void> promoteMember(String householdMemberId) async {
    final http = await _authorizedHttp();
    await http.put(
      ApiPaths.householdMemberPromote(householdMemberId),
      body: {},
    );
  }

  Future<void> demoteMember(String householdMemberId) async {
    final http = await _authorizedHttp();
    await http.put(
      ApiPaths.householdMemberDemote(householdMemberId),
      body: {},
    );
  }

  Future<void> deleteAccountByEmail(String email) async {
    final http = await _authorizedHttp();
    await http.delete(ApiPaths.userDeleteByEmail(email.trim()));
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
