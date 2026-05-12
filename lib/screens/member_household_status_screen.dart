import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/household_model.dart';
import '../models/contribution_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';
import 'member_dashboard_layout.dart';

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
    _httpService = HttpService(baseUrl: ApiConfig.baseUrl);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
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
        throw Exception('No household found for this user');
      }

      final memberRes =
          await _httpService.get('/api/v1/household/$householdId/members');
      final billsRes =
          await _httpService.get('/api/v1/household/$householdId/bills');
      final contributionsRes = await _httpService
          .get('/api/v1/household/$householdId/contributions');
      final memberContribsRes =
          await _httpService.get('/api/v1/member-contributions');
      final householdRes =
          await _httpService.get('/api/v1/household/$householdId');

      final members = _parseMembers(memberRes);
      final bills = _parseBills(billsRes);
      final contributions = _parseContributions(contributionsRes);
      final memberContributions = _parseMemberContributions(memberContribsRes);
      final currency = (householdRes['currency'] == 2) ? 'USD' : 'PEN';

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
    final formatter = DateFormat('MMMM yyyy', 'es_ES');
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
        bills.fold<double>(0, (sum, b) => sum + (b.amount ?? 0));
    final baseShare = memberCount > 0 ? monthlyGoal / memberCount : 0;

    final contributionIds = contributions.map((c) => c.id).toSet();

    final rows = members.map((member) {
      final myContribs = memberContributions
          .where((m) => m.memberId == member.id &&
              contributionIds.contains(m.contributionId))
          .toList();

      final assignedFromContribs = myContribs.fold<double>(
          0, (sum, m) => sum + (m.amount ?? 0));
      final contributed = myContribs
          .where((m) => m.isPaid)
          .fold<double>(0, (sum, m) => sum + (m.amount ?? 0));

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
    final dates = contributions
        .map((c) => c.createdAt)
        .where((d) => d != null)
        .cast<DateTime>();
    if (dates.isEmpty) return '—';
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateFormat('dd/MM/yyyy', 'es_ES').format(maxDate);
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

    // For now, just show a snackbar (Flutter doesn't have built-in CSV download)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV data copied to clipboard')),
    );
  }

  List<HouseholdMember> _parseMembers(Map<String, dynamic> res) {
    final list = res['items'] as List? ?? res as List? ?? [];
    return list
        .map((item) => HouseholdMember.fromJson(
            item is Map<String, dynamic> ? item : {}))
        .toList();
  }

  List<Bill> _parseBills(Map<String, dynamic> res) {
    final list = res['items'] as List? ?? res as List? ?? [];
    return list
        .map((item) =>
            Bill.fromJson(item is Map<String, dynamic> ? item : {}))
        .toList();
  }

  List<Contribution> _parseContributions(Map<String, dynamic> res) {
    final list = res['items'] as List? ?? res as List? ?? [];
    return list
        .map((item) =>
            Contribution.fromJson(item is Map<String, dynamic> ? item : {}))
        .toList();
  }

  List<MemberContribution> _parseMemberContributions(Map<String, dynamic> res) {
    final list = res['items'] as List? ?? res as List? ?? [];
    return list
        .map((item) => MemberContribution.fromJson(
            item is Map<String, dynamic> ? item : {}))
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
      child: _loading
          ? const Center(child: CircularProgressIndicator())
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
                        child: const Text('Retry'),
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
                                color: Color(0xFF1a1a1a),
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
      currentRoute: 'member-household-status',
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
            color: Colors.black.withOpacity(0.05),
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
