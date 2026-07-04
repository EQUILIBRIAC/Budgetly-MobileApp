import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/features/representative/presentation/providers/contribution_providers.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';

final contributionsOverviewProvider =
    FutureProvider<List<ContributionOverviewItem>>((ref) async {
  final repData = await ref.watch(representativeProvider.future);
  final sync = await ref.read(contributionSyncServiceProvider.future);

  return sync.loadContributionsOverview(
    householdId: repData.activeHouseholdId,
    contributions: repData.contributions,
    bills: repData.bills,
  );
});
