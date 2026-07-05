import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/features/member/domain/member_contribution_utils.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_dashboard_layout.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_no_household_view.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';

class MemberHouseholdStatusScreen extends StatefulWidget {
  const MemberHouseholdStatusScreen({super.key});

  @override
  State<MemberHouseholdStatusScreen> createState() =>
      _MemberHouseholdStatusScreenState();
}

class _MemberHouseholdStatusScreenState
    extends State<MemberHouseholdStatusScreen> {
  late HttpService _httpService;
  bool _loading = true;
  bool _needsHousehold = false;
  String _errorMessage = '';

  Map<String, HouseholdStatusPeriod> _datasets = {};
  List<PeriodOption> _periodOptions = [];
  String? _selectedPeriod;

  final _defaultSummary = HouseholdStatusSummary(
    totalContributed: 0,
    monthlyGoal: 0,
    progress: 0,
    contributors: 0,
    currency: 'PEN',
  );

  @override
  void initState() {
    super.initState();
    _httpService = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
        _needsHousehold = false;
      });

      // Get token from storage and set it on the service
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      _httpService.setToken(token);

      final userJson = await StorageService.getUser();
      if (userJson == null) {
        throw Exception('No user found');
      }

      final householdId = userJson['householdId']?.toString() ?? '';
      if (householdId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _needsHousehold = true;
          _loading = false;
        });
        return;
      }

      final memberRes =
          await _httpService.get(ApiPaths.householdMembersByHousehold(householdId));
      final billsRes =
          await _httpService.get(ApiPaths.billsByHousehold(householdId));
      final contributionsRes =
          await _httpService.get(ApiPaths.contributionsByHousehold(householdId));
      final householdRes =
          await _httpService.get(ApiPaths.houseHold(householdId));

      final members = _parseMembers(memberRes);
      final bills = _parseBills(billsRes);
      final contributions = _parseContributions(contributionsRes);
      final memberContributions = _dedupeAll(
        await _fetchHouseholdMemberContributions(
          members.map((m) => m.id).where((id) => id.isNotEmpty).toList(),
        ),
        contributions,
      );
      final hMap = ApiJson.objectData(householdRes);
      final currency =
          hMap != null ? Household.fromJson(hMap).currency : 'PEN';

      final memberIds = members.map((m) => m.id).toSet();
      final filteredEntries = memberContributions
          .where((entry) => memberIds.contains(entry.memberId))
          .toList();

      _buildPeriodDataset(
        members: members,
        bills: bills,
        contributions: contributions,
        memberContributions: filteredEntries,
        currency: currency,
      );

      if (_periodOptions.isNotEmpty) {
        setState(() {
          _selectedPeriod = _periodOptions.first.value;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading household status: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _buildPeriodDataset({
    required List<HouseholdMember> members,
    required List<Bill> bills,
    required List<Contribution> contributions,
    required List<MemberContribution> memberContributions,
    required String currency,
  }) {
    final Map<String, _PeriodBucket> periods = {};

    // Build periods from bills
    for (final bill in bills) {
      final key = _getPeriodKey(bill.paymentDay ?? bill.createdAt);
      _ensurePeriod(periods, key).billIds.add(bill.id);
    }

    // Build periods from contributions
    for (final contribution in contributions) {
      final bill = bills.firstWhere(
        (b) => b.id == contribution.billId,
        orElse: () =>
            Bill(id: '', householdId: '', description: '', amount: 0, category: '', paymentDay: null, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      final key = _getPeriodKey(bill.paymentDay ?? contribution.createdAt);
      final bucket = _ensurePeriod(periods, key);
      bucket.contributionIds.add(contribution.id);
      bucket.billIds.add(bill.id);
    }

    if (periods.isEmpty) {
      _ensurePeriod(periods, 'general');
    }

    // Build dataset for each period
    final newDatasets = <String, HouseholdStatusPeriod>{};
    final options = <PeriodOption>[];

    final sortedPeriods = periods.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    for (final entry in sortedPeriods) {
      final key = entry.key;
      final bucket = entry.value;

      final periodBills =
          bills.where((b) => bucket.billIds.contains(b.id)).toList();
      final periodContributions = contributions
          .where((c) => bucket.contributionIds.contains(c.id))
          .toList();
      final periodMemberContribs = memberContributions
          .where((m) => periodContributions
              .any((c) => c.id == m.contributionId))
          .toList();

      final rows = _buildRowsForPeriod(
        members: members,
        bills: periodBills,
        contributions: periodContributions,
        memberContributions: periodMemberContribs,
        currency: currency,
      );

      newDatasets[key] = rows;
      options.add(PeriodOption(
        label: _getLabel(key),
        value: key,
      ));
    }

    setState(() {
      _datasets = newDatasets;
      _periodOptions = options;
    });
  }

  String _getPeriodKey(DateTime? date) {
    if (date == null) return 'general';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _getLabel(String key) {
    if (key == 'general') return 'General';
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final date = DateTime(year, month, 1);
    final formatter = DateFormat('MMMM yyyy', EnvConfig.localeDefault);
    return formatter.format(date);
  }

  _PeriodBucket _ensurePeriod(
      Map<String, _PeriodBucket> periods, String key) {
    if (!periods.containsKey(key)) {
      periods[key] = _PeriodBucket();
    }
    return periods[key]!;
  }

  HouseholdStatusPeriod _buildRowsForPeriod({
    required List<HouseholdMember> members,
    required List<Bill> bills,
    required List<Contribution> contributions,
    required List<MemberContribution> memberContributions,
    required String currency,
  }) {
    final memberCount = members.length;
    final monthlyGoal =
        bills.fold<double>(0, (sum, b) => sum + b.amount);
    final baseShare = memberCount > 0 ? monthlyGoal / memberCount : 0;

    final contributionIds = contributions.map((c) => c.id).toSet();

    final rows = members.map((member) {
      final myContribs = memberContributions
          .where((m) => m.memberId == member.id &&
              contributionIds.contains(m.contributionId))
          .toList();

      final assignedFromContribs = myContribs.fold<double>(
          0, (sum, m) => sum + m.amount);
      final contributed = myContribs
          .where((m) => m.isPaid)
          .fold<double>(0, (sum, m) => sum + m.amount);

      final assigned = (myContribs.isNotEmpty ? assignedFromContribs : baseShare).toDouble();
      final status =
          assigned > 0 && contributed >= assigned ? 'Cumplido' : 'Pendiente';

      return HouseholdStatusRow(
        id: member.id,
        name: member.name ?? 'Miembro',
        contributed: contributed,
        assigned: assigned,
        deadline: _getDeadline(contributions),
        status: status,
      );
    }).toList();

    final totalContributed =
        rows.fold<double>(0, (sum, r) => sum + r.contributed);
    final progress =
        (monthlyGoal > 0 ? (totalContributed / monthlyGoal) * 100 : 0.0).toDouble();
    final contributors =
        rows.where((r) => r.contributed > 0).length;

    return HouseholdStatusPeriod(
      summary: HouseholdStatusSummary(
        totalContributed: totalContributed,
        monthlyGoal: monthlyGoal,
        progress: progress,
        contributors: contributors,
        currency: currency,
      ),
      rows: rows,
    );
  }

  String _getDeadline(List<Contribution> contributions) {
    if (contributions.isEmpty) return '—';
    final dates = contributions.map((c) => c.createdAt).toList();
    if (dates.isEmpty) return '—';
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateFormat('dd/MM/yyyy', EnvConfig.localeDefault).format(maxDate);
  }

  void _exportCSV() {
    if (_selectedPeriod == null) return;
    final period = _datasets[_selectedPeriod];
    if (period == null) return;

    final rows = period.rows;
    final StringBuffer csv = StringBuffer();

    // Header
    csv.writeln('Miembro,Monto aportado,Monto asignado,Fecha límite,Estado');

    // Rows
    for (final row in rows) {
      csv.writeln(
        '${row.name},'
        '${row.contributed.toStringAsFixed(2)},'
        '${row.assigned.toStringAsFixed(2)},'
        '${row.deadline},'
        '${row.status}',
      );
    }

    // Copiar CSV al portapapeles
    Clipboard.setData(ClipboardData(text: csv.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copiado al portapapeles')),
    );
  }

  Future<List<MemberContribution>> _fetchHouseholdMemberContributions(
    List<String> memberIds,
  ) async {
    if (memberIds.isEmpty) return [];

    final results = await Future.wait(
      memberIds.map((id) async {
        final res =
            await _httpService.get(ApiPaths.memberContributionsByMember(id));
        return _parseMemberContributions(res);
      }),
    );

    return results.expand((list) => list).toList();
  }

  List<MemberContribution> _dedupeAll(
    List<MemberContribution> items,
    List<Contribution> contributions,
  ) {
    return MemberContributionUtils.dedupeByContribution(
      items,
      contributionsById: {for (final c in contributions) c.id: c},
    );
  }

  List<HouseholdMember> _parseMembers(Map<String, dynamic> res) {
    return ApiJson.listDataFlexible(res).map(HouseholdMember.fromJson).toList();
  }

  List<Bill> _parseBills(Map<String, dynamic> res) {
    return ApiJson.listDataFlexible(res).map(Bill.fromJson).toList();
  }

  List<Contribution> _parseContributions(Map<String, dynamic> res) {
    return ApiJson.listDataFlexible(res).map(Contribution.fromJson).toList();
  }

  List<MemberContribution> _parseMemberContributions(Map<String, dynamic> res) {
    return ApiJson.listDataFlexible(res)
        .map(MemberContribution.fromJson)
        .toList();
  }

  String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : 'S/ ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final period = _selectedPeriod != null ? _datasets[_selectedPeriod] : null;
    final summary = period?.summary ?? _defaultSummary;
    final rows = period?.rows ?? [];

    return MemberDashboardLayout(
      currentRoute: 'member-household-status',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _needsHousehold
              ? MemberNoHouseholdView(onRetry: _loadData)
              : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and period selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Estado del hogar',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            if (_periodOptions.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedPeriod,
                                  underline: Container(),
                                  items: _periodOptions
                                      .map((option) =>
                                          DropdownMenuItem<String>(
                                            value: option.value,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                              child: Text(option.label),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPeriod = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // KPI Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            return GridView.count(
                              crossAxisCount: isMobile ? 2 : 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              children: [
                                _buildKpiCard(
                                  'Monto total aportado',
                                  _formatCurrency(
                                    summary.totalContributed,
                                    summary.currency,
                                  ),
                                  Colors.blue,
                                ),
                                _buildKpiCard(
                                  'Meta mensual',
                                  _formatCurrency(
                                    summary.monthlyGoal,
                                    summary.currency,
                                  ),
                                  Colors.green,
                                ),
                                _buildKpiCard(
                                  '% cumplimiento',
                                  '${summary.progress.toStringAsFixed(1)}%',
                                  Colors.orange,
                                ),
                                _buildKpiCard(
                                  'N° aportadores',
                                  summary.contributors.toString(),
                                  Colors.purple,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Export Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _exportCSV,
                            icon: const Icon(Icons.download),
                            label: const Text('Exportar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Data Table
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Miembro',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Monto aportado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Monto asignado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Fecha límite',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Estado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              rows: rows
                                  .map(
                                    (row) => DataRow(
                                      cells: [
                                        DataCell(Text(row.name)),
                                        DataCell(Text(
                                            'S/ ${row.contributed.toStringAsFixed(2)}')),
                                        DataCell(Text(
                                            'S/ ${row.assigned.toStringAsFixed(2)}')),
                                        DataCell(Text(row.deadline)),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: row.status == 'Cumplido'
                                                  ? Colors.green.shade100
                                                  : Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              row.status,
                                              style: TextStyle(
                                                color: row.status == 'Cumplido'
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class PeriodOption {
  final String label;
  final String value;

  PeriodOption({required this.label, required this.value});
}

class HouseholdStatusSummary {
  final double totalContributed;
  final double monthlyGoal;
  final double progress;
  final int contributors;
  final String currency;

  HouseholdStatusSummary({
    required this.totalContributed,
    required this.monthlyGoal,
    required this.progress,
    required this.contributors,
    required this.currency,
  });
}

class HouseholdStatusRow {
  final String id;
  final String name;
  final double contributed;
  final double assigned;
  final String deadline;
  final String status;

  HouseholdStatusRow({
    required this.id,
    required this.name,
    required this.contributed,
    required this.assigned,
    required this.deadline,
    required this.status,
  });
}

class HouseholdStatusPeriod {
  final HouseholdStatusSummary summary;
  final List<HouseholdStatusRow> rows;

  HouseholdStatusPeriod({
    required this.summary,
    required this.rows,
  });
}

class _PeriodBucket {
  final Set<String> billIds = {};
  final Set<String> contributionIds = {};
}

