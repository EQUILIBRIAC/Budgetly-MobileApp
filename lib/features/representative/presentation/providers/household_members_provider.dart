import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/domain/entities/member_view_model.dart';
import 'package:budgetly_app/features/representative/data/household_member_api.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';

class HouseholdMembersData {
  final String householdId;
  final String currency;
  final List<MemberViewModel> members;

  const HouseholdMembersData({
    required this.householdId,
    required this.currency,
    required this.members,
  });

  double get totalIncome => members.fold(0, (sum, m) => sum + m.income);
}

Future<HouseholdMembersData> _fetchMembers(
  String householdId,
  String currency,
) async {
  final hid = householdId.trim();
  if (hid.isEmpty) {
    throw Exception('No hay hogar activo. Crea o selecciona uno en «Hogares».');
  }

  final api = await HouseholdMemberApi.authorized();
  final members = await api.getMergedMembers(hid);
  return HouseholdMembersData(
    householdId: hid,
    currency: currency,
    members: members,
  );
}

/// Miembros unificados (nombre/email/rol + income) para Miembros e Ingresos.
final householdMembersProvider =
    FutureProvider<HouseholdMembersData>((ref) async {
  final repData = await ref.watch(representativeProvider.future);
  return _fetchMembers(repData.activeHouseholdId, repData.currency);
});

/// Alias usado por la pantalla de ingresos.
final memberIncomeProvider = householdMembersProvider;
