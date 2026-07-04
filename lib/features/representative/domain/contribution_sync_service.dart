import 'package:budgetly_app/core/storage/household_strategy_storage.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';
import 'package:budgetly_app/domain/services/bill_payment_service.dart';
import 'package:budgetly_app/domain/services/income_split_service.dart';
import 'package:budgetly_app/features/representative/data/bills_api_service.dart';
import 'package:budgetly_app/features/representative/data/contribution_api_service.dart';
import 'package:budgetly_app/features/representative/data/household_member_api.dart';
import 'package:budgetly_app/features/representative/data/income_allocation_api_service.dart';
import 'package:budgetly_app/features/representative/data/member_contribution_api_service.dart';

/// Orquesta contribuciones y desglose por miembro (persistencia en API).
class ContributionSyncService {
  ContributionSyncService({
    required BillsApiService billsApi,
    required ContributionApiService contributionApi,
    required MemberContributionApiService memberContributionApi,
    required HouseholdMemberApi membersApi,
    required IncomeAllocationApiService incomeAllocationApi,
  })  : _billsApi = billsApi,
        _contributionApi = contributionApi,
        _memberContributionApi = memberContributionApi,
        _membersApi = membersApi,
        _incomeAllocationApi = incomeAllocationApi;

  final BillsApiService _billsApi;
  final ContributionApiService _contributionApi;
  final MemberContributionApiService _memberContributionApi;
  final HouseholdMemberApi _membersApi;
  final IncomeAllocationApiService _incomeAllocationApi;

  static Future<ContributionSyncService> authorized() async {
    return ContributionSyncService(
      billsApi: await BillsApiService.authorized(),
      contributionApi: await ContributionApiService.authorized(),
      memberContributionApi: await MemberContributionApiService.authorized(),
      membersApi: await HouseholdMemberApi.authorized(),
      incomeAllocationApi: await IncomeAllocationApiService.authorized(),
    );
  }

  Future<List<MemberIncomeProfile>> loadActiveMemberProfiles(
    String householdId,
  ) async {
    final merged = await _membersApi.getMergedMembers(householdId);
    final profiles = MemberIncomeProfile.fromMemberViewModels(merged);
    return IncomeSplitService.calculatePercentages(profiles);
  }

  Future<void> syncIncomeAllocations({
    required String householdId,
    required List<MemberIncomeProfile> profiles,
  }) async {
    for (final profile in profiles) {
      if (profile.income <= 0) continue;
      final uid = int.tryParse(profile.userId);
      if (uid == null || uid <= 0) continue;
      try {
        await _incomeAllocationApi.create(
          userId: uid,
          householdId: householdId,
          percentage: profile.percentage,
        );
      } catch (_) {
        // Opcional: el backend puede rechazar duplicados.
      }
    }
  }

  Future<ContributionDto> ensureContribution({
    required BillDto bill,
    required EStrategy strategy,
  }) async {
    final deadline = bill.paymentDate ?? DateTime.now().add(const Duration(days: 15));
    final description = 'Aporte ${bill.description}';

    var contribution = await _contributionApi.getByBillId(bill.id);
    if (contribution == null) {
      return _contributionApi.create(
        billId: bill.id,
        householdId: bill.householdId,
        description: description,
        deadlineForMembers: deadline,
        strategy: strategy,
      );
    }

    if (contribution.strategy != strategy) {
      return _contributionApi.update(
        id: contribution.id,
        description: contribution.description ?? description,
        deadlineForMembers: contribution.deadlineForMembers ?? deadline,
        strategy: strategy,
      );
    }

    return contribution;
  }

  Future<List<MemberContributionDto>> ensureMemberContributions({
    required ContributionDto contribution,
    required BillDto bill,
    required EStrategy strategy,
    required List<MemberIncomeProfile> profiles,
  }) async {
    final existingRaw =
        await _memberContributionApi.getByContributionId(contribution.id);
    final normalized = BillPaymentService.normalizeForHousehold(
      rows: existingRaw,
      activeProfiles: profiles,
    );
    final existingMemberIds = normalized.map((e) => e.memberId).toSet();

    if (strategy == EStrategy.incomeBased &&
        IncomeSplitService.totalIncome(profiles) <= 0) {
      throw Exception(
        'Registra ingresos antes de activar IncomeBased',
      );
    }

    final breakdown = IncomeSplitService.calculateSplit(
      billAmount: bill.amount,
      strategy: strategy,
      members: profiles,
    );

    final created = <MemberContributionDto>[];
    for (final item in breakdown) {
      if (item.householdMemberId.isEmpty) continue;
      if (existingMemberIds.contains(item.householdMemberId)) continue;
      final row = await _memberContributionApi.create(
        contributionId: contribution.id,
        memberId: item.householdMemberId,
        amount: item.assignedAmount,
      );
      created.add(row);
      existingMemberIds.add(item.householdMemberId);
    }

    return BillPaymentService.normalizeForHousehold(
      rows: [...existingRaw, ...created],
      activeProfiles: profiles,
    );
  }

  Future<BillBreakdownViewModel> loadOrCreateBreakdown({
    required BillDto bill,
    EStrategy? strategyOverride,
  }) async {
    final strategy = strategyOverride ??
        await HouseholdStrategyStorage.loadDefaultStrategy(bill.householdId);

    final profiles = await loadActiveMemberProfiles(bill.householdId);
    final contribution = await ensureContribution(bill: bill, strategy: strategy);
    final memberRows = await ensureMemberContributions(
      contribution: contribution,
      bill: bill,
      strategy: strategy,
      profiles: profiles,
    );

    final profileByMemberId = {
      for (final p in profiles) p.householdMemberId: p,
    };

    final items = memberRows.map((row) {
      final profile = profileByMemberId[row.memberId];
      return BillBreakdownItem(
        householdMemberId: row.memberId,
        userId: profile?.userId ?? '',
        name: profile?.name ?? 'Sin nombre',
        percentage: profile?.percentage ?? 0,
        assignedAmount: row.amount,
      );
    }).toList();

    if (items.isEmpty) {
      final calculated = IncomeSplitService.calculateSplit(
        billAmount: bill.amount,
        strategy: strategy,
        members: profiles,
      );
      return BillBreakdownViewModel(
        bill: bill,
        contribution: contribution,
        strategy: strategy,
        items: calculated,
      );
    }

    return BillBreakdownViewModel(
      bill: bill,
      contribution: contribution,
      strategy: strategy,
      items: items,
    );
  }

  /// Recalcula y persiste desglose IncomeBased para todas las facturas del hogar.
  Future<void> syncAllBillsForHousehold({
    required String householdId,
    required EStrategy strategy,
  }) async {
    final profiles = await loadActiveMemberProfiles(householdId);

    if (strategy == EStrategy.incomeBased &&
        IncomeSplitService.totalIncome(profiles) <= 0) {
      throw Exception(
        'Registra ingresos antes de activar IncomeBased',
      );
    }

    final bills = await _billsApi.getByHousehold(householdId);
    for (final bill in bills) {
      final contribution = await ensureContribution(bill: bill, strategy: strategy);
      await ensureMemberContributions(
        contribution: contribution,
        bill: bill,
        strategy: strategy,
        profiles: profiles,
      );
    }
  }

  /// Carga contribuciones con desglose por miembro para la pantalla de Aportes.
  Future<List<ContributionOverviewItem>> loadContributionsOverview({
    required String householdId,
    required List<Contribution> contributions,
    required List<Bill> bills,
  }) async {
    if (contributions.isEmpty) return const [];

    final profiles = await loadActiveMemberProfiles(householdId);
    final profileByMemberId = {
      for (final p in profiles) p.householdMemberId: p,
    };
    final billsById = {for (final b in bills) b.id: b};
    final defaultStrategy =
        await HouseholdStrategyStorage.loadDefaultStrategy(householdId);

    final overview = <ContributionOverviewItem>[];

    for (final contribution in contributions) {
      final bill = billsById[contribution.billId];
      final billDto = bill != null ? BillDto.fromBill(bill) : null;

      var strategy = contribution.strategy;
      if (strategy == EStrategy.even &&
          defaultStrategy == EStrategy.incomeBased) {
        strategy = defaultStrategy;
      }

      List<MemberContributionDto> memberRows;
      if (billDto != null) {
        final ensured = await ensureContribution(
          bill: billDto,
          strategy: strategy,
        );
        memberRows = await ensureMemberContributions(
          contribution: ensured,
          bill: billDto,
          strategy: strategy,
          profiles: profiles,
        );
        strategy = ensured.strategy;
      } else {
        memberRows = BillPaymentService.normalizeForHousehold(
          rows: await _memberContributionApi.getByContributionId(
            contribution.id,
          ),
          activeProfiles: profiles,
        );
      }

      List<BillBreakdownItem> shares;
      if (memberRows.isNotEmpty) {
        shares = memberRows.map((row) {
          final profile = profileByMemberId[row.memberId];
          return BillBreakdownItem(
            householdMemberId: row.memberId,
            userId: profile?.userId ?? '',
            name: profile?.name ?? 'Sin nombre',
            percentage: profile?.percentage ?? 0,
            assignedAmount: row.amount,
          );
        }).toList();
      } else if (billDto != null) {
        shares = IncomeSplitService.calculateSplit(
          billAmount: billDto.amount,
          strategy: strategy,
          members: profiles,
        );
      } else {
        shares = const [];
      }

      overview.add(
        ContributionOverviewItem(
          contributionId: contribution.id,
          billId: contribution.billId,
          description: contribution.description,
          deadlineForMembers: contribution.deadlineForMembers,
          strategy: strategy,
          billAmount: bill?.amount ?? 0,
          billDescription: bill?.description,
          memberShares: shares,
        ),
      );
    }

    return overview;
  }

  Future<void> saveIncomeBasedConfiguration({
    required String householdId,
    required bool enabled,
  }) async {
    final strategy =
        enabled ? EStrategy.incomeBased : EStrategy.even;

    await HouseholdStrategyStorage.saveDefaultStrategy(householdId, strategy);

    final profiles = await loadActiveMemberProfiles(householdId);
    if (enabled && IncomeSplitService.totalIncome(profiles) <= 0) {
      throw Exception(
        'Registra ingresos antes de activar IncomeBased',
      );
    }

    await syncIncomeAllocations(
      householdId: householdId,
      profiles: profiles,
    );

    await syncAllBillsForHousehold(
      householdId: householdId,
      strategy: strategy,
    );
  }
}
