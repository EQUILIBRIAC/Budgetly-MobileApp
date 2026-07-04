import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/features/representative/domain/contribution_sync_service.dart';

final contributionSyncServiceProvider =
    FutureProvider<ContributionSyncService>((ref) async {
  return ContributionSyncService.authorized();
});
