import 'package:budgetly_app/core/storage/household_strategy_storage.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';
import 'package:budgetly_app/domain/services/bill_payment_service.dart';
import 'package:budgetly_app/features/representative/data/contribution_api_service.dart';
import 'package:budgetly_app/features/representative/data/household_member_api.dart';
import 'package:budgetly_app/features/representative/data/member_contribution_api_service.dart';
import 'package:budgetly_app/features/representative/domain/contribution_sync_service.dart';

class BillPaymentLoadService {
  BillPaymentLoadService({
    required ContributionSyncService syncService,
    required ContributionApiService contributionApi,
    required MemberContributionApiService memberContributionApi,
    required HouseholdMemberApi membersApi,
  })  : _syncService = syncService,
        _contributionApi = contributionApi,
        _memberContributionApi = memberContributionApi,
        _membersApi = membersApi;

  final ContributionSyncService _syncService;
  final ContributionApiService _contributionApi;
  final MemberContributionApiService _memberContributionApi;
  final HouseholdMemberApi _membersApi;

  static Future<BillPaymentLoadService> authorized() async {
    return BillPaymentLoadService(
      syncService: await ContributionSyncService.authorized(),
      contributionApi: await ContributionApiService.authorized(),
      memberContributionApi: await MemberContributionApiService.authorized(),
      membersApi: await HouseholdMemberApi.authorized(),
    );
  }

  Future<BillPaymentsViewModel> load({
    required Bill bill,
  }) async {
    final billDto = BillDto.fromBill(bill);
    final strategy =
        await HouseholdStrategyStorage.loadDefaultStrategy(bill.householdId);
    final profiles =
        await _syncService.loadActiveMemberProfiles(bill.householdId);

    var contribution = await _contributionApi.getByBillId(bill.id);
    contribution ??= await _syncService.ensureContribution(
      bill: billDto,
      strategy: strategy,
    );

    final memberRows = await _syncService.ensureMemberContributions(
      contribution: contribution,
      bill: billDto,
      strategy: strategy,
      profiles: profiles,
    );

    final members = await _membersApi.getMergedMembers(bill.householdId);
    final paymentItems = BillPaymentService.mergeWithMemberNames(
      contributions: memberRows,
      members: members,
    );
    final progress = BillPaymentService.buildProgress(
      billId: bill.id,
      billTotalAmount: bill.amount,
      contributions: memberRows,
    );

    return BillPaymentsViewModel(
      bill: billDto,
      contribution: contribution,
      progress: progress,
      members: paymentItems,
    );
  }

  Future<BillPaymentProgress> loadProgressForBill(Bill bill) async {
    final contribution = await _contributionApi.getByBillId(bill.id);
    if (contribution == null) {
      return BillPaymentProgress.empty(
        billId: bill.id,
        billTotalAmount: bill.amount,
      );
    }

    final profiles =
        await _syncService.loadActiveMemberProfiles(bill.householdId);
    final memberRowsRaw =
        await _memberContributionApi.getByContributionId(contribution.id);
    final memberRows = BillPaymentService.normalizeForHousehold(
      rows: memberRowsRaw,
      activeProfiles: profiles,
    );
    return BillPaymentService.buildProgress(
      billId: bill.id,
      billTotalAmount: bill.amount,
      contributions: memberRows,
    );
  }
}
