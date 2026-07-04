import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/core/storage/household_strategy_storage.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/domain/services/income_split_service.dart';
import 'package:budgetly_app/features/representative/presentation/providers/contribution_overview_provider.dart';
import 'package:budgetly_app/features/representative/presentation/providers/contribution_providers.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';

class HouseholdSettingsData {
  final String householdId;
  final String currency;
  final bool incomeBasedEnabled;
  final EStrategy defaultStrategy;
  final List<MemberIncomeProfile> members;
  final double totalIncome;

  const HouseholdSettingsData({
    required this.householdId,
    required this.currency,
    required this.incomeBasedEnabled,
    required this.defaultStrategy,
    required this.members,
    required this.totalIncome,
  });
}

final householdSettingsProvider =
    FutureProvider<HouseholdSettingsData>((ref) async {
  final repData = await ref.watch(representativeProvider.future);
  final householdId = repData.activeHouseholdId;

  final sync = await ref.watch(contributionSyncServiceProvider.future);
  final profiles = await sync.loadActiveMemberProfiles(householdId);
  final strategy = await HouseholdStrategyStorage.loadDefaultStrategy(householdId);

  return HouseholdSettingsData(
    householdId: householdId,
    currency: repData.currency,
    incomeBasedEnabled: strategy == EStrategy.incomeBased,
    defaultStrategy: strategy,
    members: profiles,
    totalIncome: IncomeSplitService.totalIncome(profiles),
  );
});

class HouseholdSettingsActions {
  HouseholdSettingsActions(this._ref);

  final Ref _ref;

  Future<void> saveIncomeBasedConfiguration({
    required String householdId,
    required bool enabled,
  }) async {
    final sync = await _ref.read(contributionSyncServiceProvider.future);
    await sync.saveIncomeBasedConfiguration(
      householdId: householdId,
      enabled: enabled,
    );
    _ref.invalidate(householdSettingsProvider);
    _ref.invalidate(contributionsOverviewProvider);
    _ref.invalidate(representativeProvider);
  }
}

final householdSettingsActionsProvider =
    Provider<HouseholdSettingsActions>((ref) {
  return HouseholdSettingsActions(ref);
});
