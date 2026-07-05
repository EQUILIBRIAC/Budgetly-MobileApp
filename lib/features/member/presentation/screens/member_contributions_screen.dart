import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/payment_entities.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:budgetly_app/features/member/domain/member_contribution_utils.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_dashboard_layout.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_no_household_view.dart';
import 'package:budgetly_app/features/representative/data/member_contribution_api_service.dart';
import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_page_styles.dart';

class MemberContributionsScreen extends ConsumerStatefulWidget {
  const MemberContributionsScreen({super.key});

  @override
  ConsumerState<MemberContributionsScreen> createState() =>
      _MemberContributionsScreenState();
}

class _MemberContributionsScreenState
    extends ConsumerState<MemberContributionsScreen> {  late final TextEditingController _incomeController;
  bool _isLoading = true;
  bool _needsHousehold = false;
  bool _isSavingIncome = false;
  String _error = '';
  String _success = '';

  List<MemberContribution> _memberContributions = [];
  List<Contribution> _contributions = [];
  List<Bill> _bills = [];
  String _memberId = '';
  double _currentIncome = 0.0;
  final Set<String> _markingIds = {};

  Map<String, Contribution> get _contributionsById => {
        for (final c in _contributions) c.id: c,
      };

  Map<String, Bill> get _billsById => {
        for (final b in _bills) b.id: b,
      };

  List<MemberContribution> get _myContributions {
    final validIds = _contributions.map((c) => c.id).toSet();
    final deduped = MemberContributionUtils.dedupeByContribution(
      _memberContributions,
      validContributionIds: validIds.isEmpty ? null : validIds,
      contributionsById: _contributionsById,
    );
    if (_memberId.isEmpty) return deduped;
    return deduped.where((c) => c.memberId == _memberId).toList();
  }

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
      _needsHousehold = false;
    });

    try {
      final userStr = await _getStoredUser();
      if (userStr == null) throw Exception('Usuario no encontrado');

      final user = userStr;
      final householdId = _toString(user['householdId']);
      if (householdId == null || householdId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _needsHousehold = true;
          _isLoading = false;
        });
        return;
      }

      final httpService = HttpService(baseUrl: EnvConfig.apiBaseUrl);
      final token = await StorageService.getToken();
      if (token != null) {
        httpService.setToken(token);
      }

      final memberList = await _fetchMembers(httpService, householdId);
      final userId = _toString(user['id']);
      final member = memberList.firstWhere(
        (m) => m.userId == userId,
        orElse: () => HouseholdMember(
          id: '',
          userId: userId ?? '',
          householdId: householdId,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final memberContribs = member.id.isNotEmpty
          ? await _fetchMemberContributions(httpService, member.id)
          : <MemberContribution>[];

      final contributions =
          await _fetchContributions(httpService, householdId);
      final bills = await _fetchBills(httpService, householdId);

      if (!mounted) return;
      setState(() {
        _memberContributions = memberContribs;
        _contributions = contributions;
        _bills = bills;
        _memberId = member.id;
        _currentIncome = member.income ?? 0.0;
        _incomeController.text = _currentIncome.toStringAsFixed(2);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<List<HouseholdMember>> _fetchMembers(
    HttpService httpService,
    String householdId,
  ) async {
    final response = await httpService.get(
      ApiPaths.householdMembersByHousehold(householdId),
    );
    return ApiJson.listDataFlexible(response)
        .map((json) => HouseholdMember.fromJson(json))
        .toList();
  }

  Future<List<MemberContribution>> _fetchMemberContributions(
    HttpService httpService,
    String memberId,
  ) async {
    final response =
        await httpService.get(ApiPaths.memberContributionsByMember(memberId));
    return ApiJson.listDataFlexible(response)
        .map((json) => MemberContribution.fromJson(json))
        .toList();
  }

  Future<List<Contribution>> _fetchContributions(
    HttpService httpService,
    String householdId,
  ) async {
    final response =
        await httpService.get(ApiPaths.contributionsByHousehold(householdId));
    return ApiJson.listDataFlexible(response)
        .map((json) => Contribution.fromJson(json))
        .toList();
  }

  Future<List<Bill>> _fetchBills(
    HttpService httpService,
    String householdId,
  ) async {
    final response = await httpService.get(ApiPaths.billsByHousehold(householdId));
    return ApiJson.listDataFlexible(response)
        .map((json) => Bill.fromJson(json))
        .toList();
  }

  Future<dynamic> _getStoredUser() async {
    // Use real StorageService to get stored user data
    try {
      final user = await StorageService.getUser();
      if (user == null) return null;
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveIncome() async {
    if (_memberId.isEmpty) return;

    setState(() {
      _error = '';
      _success = '';
      _isSavingIncome = true;
    });

    try {
      final httpService = HttpService(baseUrl: EnvConfig.apiBaseUrl);
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        httpService.setToken(token);
      }
      final user = await StorageService.getUser();
      if (user == null) throw Exception('Usuario no encontrado');
      final userIdStr = _toString(user['id']);
      final uid = int.tryParse(userIdStr ?? '');
      if (uid == null) throw Exception('ID de usuario inválido');

      await httpService.put(
        ApiPaths.householdMemberById(_memberId),
        body: {
          'householdId': null,
          'userId': uid,
          'isRepresentative': null,
          'income': double.parse(_incomeController.text),
        },
      );

      setState(() {
        _currentIncome = double.parse(_incomeController.text);
        _success = context.l10n.incomeUpdatedSuccess;
        _isSavingIncome = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isSavingIncome = false;
      });
    }
  }

  String _formatCurrency(double value) {
    return 'S/ ${value.toStringAsFixed(2)}';
  }

  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    return value.toString();
  }

  String _contribLabel(MemberContribution contrib) =>
      MemberContributionUtils.labelFor(
        contrib,
        contributionsById: _contributionsById,
        billsById: _billsById,
      );

  Future<void> _markAsPaid(MemberContribution contrib) async {
    final perms = ref.read(appPermissionsProvider);
    if (!perms.canMarkPaymentFor(contrib.memberId)) return;
    if (contrib.id.isEmpty || contrib.isPaid) return;

    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.markPayment),
        content: Text(
          l.markAsPaidConfirm(
            _formatCurrency(contrib.amount),
            _contribLabel(contrib),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _markingIds.add(contrib.id));
    try {
      final api = await MemberContributionApiService.authorized();
      await api.markAsPaid(memberContributionId: contrib.id);
      if (!mounted) return;
      setState(() {
        _memberContributions = _memberContributions.map((c) {
          if (c.id != contrib.id) return c;
          return MemberContribution(
            id: c.id,
            memberId: c.memberId,
            contributionId: c.contributionId,
            amount: c.amount,
            status: 1,
            payedAt: DateTime.now(),
            createdAt: c.createdAt,
            updatedAt: DateTime.now(),
          );
        }).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.paymentRegisteredSuccess)),
        );
      }
    } on MarkPaidEndpointMissingException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.paymentsNotSupportedYet)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _markingIds.remove(contrib.id));
    }
  }

  Map<String, double> get _totals {
    final myContributions = _myContributions;

    final assigned = myContributions.fold<double>(
      0,
      (sum, c) => sum + c.amount,
    );

    final paid = myContributions
        .where((c) => c.isPaid)
        .fold<double>(0, (sum, c) => sum + c.amount);

    return {
      'assigned': assigned,
      'paid': paid,
      'pending': assigned - paid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final perms = ref.watch(appPermissionsProvider);

    return MemberDashboardLayout(
      currentRoute: 'member-contributions',
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const SizedBox(
                  height: 500,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _needsHousehold
                  ? MemberNoHouseholdView(onRetry: _loadData)
                  : _error.isNotEmpty
                  ? SizedBox(
                      height: 500,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text(l.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        l.myContributionsTitle,
                        style: MemberPageStyles.pageTitle(context),
                      ),
                      const SizedBox(height: 20),

                      // Income Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.monthlyIncome,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.incomePrivacyHint,
                                style: MemberPageStyles.bodyMuted(context),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _incomeController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        hintText: l.currencyHint,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _isSavingIncome
                                        ? null
                                        : () {
                                            final newIncome =
                                                double.tryParse(_incomeController.text) ?? 0;
                                            if (newIncome != _currentIncome) {
                                              _saveIncome();
                                            }
                                          },
                                    icon: const Icon(Icons.save),
                                    label: Text(l.save),
                                  ),
                                ],
                              ),
                              if (_success.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _success,
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                              if (_error.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _error,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Summary Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.yourContributions,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildPill(
                                    l.totalAssigned,
                                    _formatCurrency(_totals['assigned'] ?? 0),
                                    Colors.blue,
                                  ),
                                  _buildPill(
                                    l.paid,
                                    _formatCurrency(_totals['paid'] ?? 0),
                                    Colors.green,
                                  ),
                                  _buildPill(
                                    l.pending,
                                    _formatCurrency(_totals['pending'] ?? 0),
                                    Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Contributions Table
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.registeredContributions,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _myContributions.isEmpty
                                  ? Text(
                                      l.noContributionsYet,
                                      style: MemberPageStyles.bodyMuted(context),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: [
                                          DataColumn(label: Text(l.expense)),
                                          DataColumn(label: Text(l.amount)),
                                          DataColumn(label: Text(l.status)),
                                          DataColumn(label: Text(l.action)),
                                        ],
                                        rows: _myContributions
                                            .map(
                                              (contrib) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(_contribLabel(contrib)),
                                                  ),
                                                  DataCell(
                                                    Text(_formatCurrency(contrib.amount)),
                                                  ),
                                                  DataCell(
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: contrib.isPaid
                                                            ? Colors.green.shade100
                                                            : Colors.orange.shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        contrib.isPaid
                                                            ? l.paid
                                                            : l.pending,
                                                        style: TextStyle(
                                                          color: contrib.isPaid
                                                              ? Colors.green.shade700
                                                              : Colors.orange.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    contrib.isPaid ||
                                                            !perms.canMarkPaymentFor(
                                                              contrib.memberId,
                                                            )
                                                        ? const SizedBox.shrink()
                                                        : _markingIds.contains(contrib.id)
                                                            ? const SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                ),
                                                              )
                                                            : TextButton(
                                                                onPressed: () =>
                                                                    _markAsPaid(contrib),
                                                                child: Text(
                                                                  l.markPayment,
                                                                ),
                                                              ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

