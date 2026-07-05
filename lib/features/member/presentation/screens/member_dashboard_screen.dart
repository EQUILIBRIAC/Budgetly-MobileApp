import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/features/member/domain/member_contribution_utils.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_dashboard_layout.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_no_household_view.dart';
import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_page_styles.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  bool _isLoading = true;
  bool _needsHousehold = false;
  String _error = '';

  List<MemberContribution> _memberContributions = [];
  List<Contribution> _contributions = [];
  List<Bill> _bills = [];
  List<String> _categories = [];
  String _currency = 'PEN';

  // Filters — "Todos" por defecto: el API suele tener vencimientos en meses distintos al actual.
  String _dateRangeType = 'all'; // all, current, last3, custom
  DateTimeRange? _customRange;
  String _categoryFilter = 'all';
  bool _onlyOverdue = false;
  bool _onlyPending = false;

  Map<String, Contribution> get _contributionsById => {
        for (final c in _contributions) c.id: c,
      };

  Map<String, Bill> get _billsById => {
        for (final b in _bills) b.id: b,
      };

  List<MemberContribution> get _activeContributions {
    final validIds = _contributions.map((c) => c.id).toSet();
    return MemberContributionUtils.dedupeByContribution(
      _memberContributions,
      validContributionIds: validIds,
      contributionsById: _contributionsById,
    );
  }

  DateTime _dueDate(MemberContribution item) =>
      MemberContributionUtils.dueDate(
        item,
        contributionsById: _contributionsById,
        billsById: _billsById,
      );

  DateTime _periodDate(MemberContribution item) =>
      MemberContributionUtils.periodDate(
        item,
        contributionsById: _contributionsById,
        billsById: _billsById,
      );

  String? _categoryFor(MemberContribution item) {
    final billId = _contributionsById[item.contributionId]?.billId;
    if (billId == null || billId.isEmpty) return null;
    return _billsById[billId]?.category;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
      _needsHousehold = false;
    });

    try {
      final user = await StorageService.getUser();
      if (user == null) throw Exception('Usuario no encontrado');

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

      final members = await _fetchMembers(httpService, householdId);
      final userId = _toString(user['id']);
      final member = members.cast<HouseholdMember?>().firstWhere(
            (m) => m!.userId == userId,
            orElse: () => null,
          );
      final memberId = member?.id ?? '';

      final memberContribs = memberId.isNotEmpty
          ? await _fetchMemberContributions(httpService, memberId)
          : <MemberContribution>[];

      final contributions =
          await _fetchContributions(httpService, householdId);
      final bills = await _fetchBills(httpService, householdId);
      final household = await _fetchHousehold(httpService, householdId);

      final categories = <String>{};
      for (final bill in bills) {
        if (bill.category != null && bill.category!.isNotEmpty) {
          categories.add(bill.category!);
        }
      }

      final householdData = household.isNotEmpty
          ? Household.fromJson(household[0] as Map<String, dynamic>)
          : null;

      if (!mounted) return;
      setState(() {
        _memberContributions = memberContribs;
        _contributions = contributions;
        _bills = bills;
        _categories = categories.toList()..sort();
        _currency = householdData?.currency ?? 'PEN';
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
    final response =
        await httpService.get(ApiPaths.householdMembersByHousehold(householdId));
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

  Future<List<dynamic>> _fetchHousehold(
    HttpService httpService,
    String householdId,
  ) async {
    final response = await httpService.get(ApiPaths.houseHold(householdId));
    final map = ApiJson.objectData(response);
    if (map == null) return [];
    return [map];
  }

  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    return value.toString();
  }

  List<MemberContribution> get _filteredItems {
    final now = DateTime.now();
    final (startDate, endDate) = _resolveDateRange();

    return _activeContributions.where((item) {
      final period = _periodDate(item);

      if (startDate != null && period.isBefore(startDate)) return false;
      if (endDate != null && period.isAfter(endDate)) return false;

      if (_categoryFilter != 'all') {
        final cat = _categoryFor(item);
        if (cat != _categoryFilter) return false;
      }

      if (_onlyOverdue) {
        final due = _dueDate(item);
        final isOverdue = !item.isPaid && due.isBefore(now);
        if (!isOverdue) return false;
      }

      if (_onlyPending && item.isPaid) return false;

      return true;
    }).toList();
  }

  (DateTime?, DateTime?) _resolveDateRange() {
    final now = DateTime.now();

    if (_dateRangeType == 'all') {
      return (null, null);
    }

    if (_dateRangeType == 'current') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return (start, end);
    }

    if (_dateRangeType == 'last3') {
      final start = DateTime(now.year, now.month - 2, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return (start, end);
    }

    if (_dateRangeType == 'custom' && _customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end
          .add(const Duration(hours: 23, minutes: 59, seconds: 59));
      return (start, end);
    }

    return (null, null);
  }

  Map<String, double> get _totals {
    final (startDate, endDate) = _resolveDateRange();

    final filtered = _activeContributions.where((item) {
      final period = _periodDate(item);
      if (startDate != null && period.isBefore(startDate)) return false;
      if (endDate != null && period.isAfter(endDate)) return false;
      return true;
    }).toList();

    final assigned = filtered.fold<double>(0, (sum, c) => sum + c.amount);
    final paid =
        filtered.where((c) => c.isPaid).fold<double>(0, (sum, c) => sum + c.amount);

    return {
      'assigned': assigned,
      'paid': paid,
      'pending': assigned - paid,
    };
  }

  int get _overdueCount {
    final now = DateTime.now();
    return _filteredItems
        .where((item) => !item.isPaid && _dueDate(item).isBefore(now))
        .length;
  }

  double get _upcomingAmount {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return _activeContributions
        .where((item) {
          final due = _dueDate(item);
          return !item.isPaid && due.isAfter(now) && due.isBefore(limit);
        })
        .fold<double>(0, (sum, c) => sum + c.amount);
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      symbol: _currency == 'USD' ? '\$' : 'S/.',
      locale: _currency == 'USD' ? 'en_US' : 'es_PE',
      decimalDigits: 2,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return MemberDashboardLayout(
      currentRoute: 'member-dashboard',
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const SizedBox(
                  height: 500,
                  child: Center(child: CircularProgressIndicator()),
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
                            Text(
                              l.home,
                              style: MemberPageStyles.pageTitle(context),
                            ),
                            const SizedBox(height: 20),
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.filters,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _buildDateRangeDropdown(),
                                        _buildCategoryDropdown(),
                                        _buildCheckbox(
                                          l.onlyOverdue,
                                          _onlyOverdue,
                                          (v) => setState(
                                            () => _onlyOverdue = v ?? false,
                                          ),
                                        ),
                                        _buildCheckbox(
                                          l.onlyPending,
                                          _onlyPending,
                                          (v) => setState(
                                            () => _onlyPending = v ?? false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width > 1200
                                      ? 4
                                      : 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildKpiCard(
                                  l.totalAssigned,
                                  _formatCurrency(_totals['assigned'] ?? 0),
                                  Colors.blue,
                                ),
                                _buildKpiCard(
                                  l.paid,
                                  _formatCurrency(_totals['paid'] ?? 0),
                                  Colors.green,
                                ),
                                _buildKpiCard(
                                  l.pending,
                                  _formatCurrency(_totals['pending'] ?? 0),
                                  Colors.orange,
                                ),
                                _buildKpiCard(
                                  l.next7Days,
                                  _formatCurrency(_upcomingAmount),
                                  Colors.purple,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.overdueContributions),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$_overdueCount',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l.overdueContributionsHint,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.contributionsSummary,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _filteredItems.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Text(
                                              l.noDataForFilters,
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columns: [
                                                DataColumn(label: Text(l.expense)),
                                                DataColumn(label: Text(l.amount)),
                                                DataColumn(label: Text(l.status)),
                                                DataColumn(label: Text(l.dueDate)),
                                              ],
                                              rows: _filteredItems
                                                  .map(
                                                    (item) => DataRow(
                                                      cells: [
                                                        DataCell(
                                                          Text(
                                                            MemberContributionUtils.labelFor(
                                                              item,
                                                              contributionsById:
                                                                  _contributionsById,
                                                              billsById: _billsById,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(_formatCurrency(
                                                              item.amount)),
                                                        ),
                                                        DataCell(
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: item.isPaid
                                                                  ? Colors.green
                                                                      .shade100
                                                                  : Colors.orange
                                                                      .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: Text(
                                                              item.isPaid
                                                                  ? l.paid
                                                                  : l.pending,
                                                              style: TextStyle(
                                                                color: item
                                                                        .isPaid
                                                                    ? Colors
                                                                        .green
                                                                        .shade700
                                                                    : Colors
                                                                        .orange
                                                                        .shade700,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            _formatDate(
                                                              _dueDate(item),
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

  Widget _buildDateRangeDropdown() {
    final l = context.l10n;
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: DropdownButton<String>(
        value: _dateRangeType,
        isExpanded: true,
        items: [
          DropdownMenuItem(value: 'all', child: Text(l.all)),
          DropdownMenuItem(value: 'current', child: Text(l.currentMonth)),
          DropdownMenuItem(value: 'last3', child: Text(l.last3Months)),
          DropdownMenuItem(value: 'custom', child: Text(l.customRange)),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _dateRangeType = value;
              if (value != 'custom') {
                _customRange = null;
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final l = context.l10n;
    final options = ['all', ..._categories];
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: DropdownButton<String>(
        value: _categoryFilter,
        isExpanded: true,
        items: options
            .map(
              (cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat == 'all' ? l.allFeminine : cat),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _categoryFilter = value);
          }
        },
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
