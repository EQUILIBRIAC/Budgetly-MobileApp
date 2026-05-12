import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/contribution_model.dart';
import '../models/household_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';
import 'member_dashboard_layout.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  bool _isLoading = true;
  String _error = '';

  List<MemberContribution> _memberContributions = [];
  List<String> _categories = [];
  String _currency = 'PEN';

  // Filters
  String _dateRangeType = 'current'; // current, last3, custom
  DateTimeRange? _customRange;
  String _categoryFilter = 'all';
  bool _onlyOverdue = false;
  bool _onlyPending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await StorageService.getUser();
      if (user == null) throw Exception('Usuario no encontrado');

      final householdId = _toString(user['householdId']);
      if (householdId == null || householdId.isEmpty) {
        throw Exception('Hogar no encontrado');
      }

      final userId = _toString(user['id']) ?? '';
      final httpService = HttpService(baseUrl: ApiConfig.baseUrl);
      
      // Set token on the service
      final token = await StorageService.getToken();
      if (token != null) {
        httpService.setToken(token);
      }

      final [memberList, memberContribs, household] = await Future.wait([
        _fetchMembers(httpService, householdId),
        _fetchMemberContributions(httpService),
        _fetchHousehold(httpService, householdId),
      ]);

      final bills = await _fetchBills(httpService, householdId);

      // Extract categories from bills
      final categories = <String>{};
      for (var bill in bills) {
        if (bill.category != null && bill.category!.isNotEmpty) {
          categories.add(bill.category!);
        }
      }

      final householdData = household.isNotEmpty
          ? Household.fromJson(household[0] as Map<String, dynamic>)
          : null;

      setState(() {
        _memberContributions = memberContribs as List<MemberContribution>;
        _categories = categories.toList()..sort();
        _currency = householdData?.currency ?? 'PEN';
        _isLoading = false;
      });
    } catch (e) {
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
    try {
      final response =
          await httpService.get('/api/v1/household/$householdId/members');
      final list = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map((json) => HouseholdMember.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<MemberContribution>> _fetchMemberContributions(
    HttpService httpService,
  ) async {
    try {
      final response = await httpService.get('/api/v1/member-contributions');
      final list = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map((json) => MemberContribution.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Bill>> _fetchBills(
    HttpService httpService,
    String householdId,
  ) async {
    try {
      final response = await httpService.get('/api/v1/household/$householdId/bills');
      final list = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map((json) => Bill.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _fetchHousehold(
    HttpService httpService,
    String householdId,
  ) async {
    try {
      final response = await httpService.get('/api/v1/household/$householdId');
      return response['data'] is List ? response['data'] : [response['data']];
    } catch (e) {
      return [];
    }
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

    return _memberContributions.where((item) {
      final due = item.updatedAt;

      if (startDate != null && due.isBefore(startDate)) return false;
      if (endDate != null && due.isAfter(endDate)) return false;

      if (_onlyOverdue) {
        final isOverdue = !item.isPaid && due.isBefore(now);
        if (!isOverdue) return false;
      }

      if (_onlyPending && item.isPaid) return false;

      return true;
    }).toList();
  }

  (DateTime?, DateTime?) _resolveDateRange() {
    final now = DateTime.now();

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
      final end = _customRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      return (start, end);
    }

    return (null, null);
  }

  Map<String, double> get _totals {
    final (startDate, endDate) = _resolveDateRange();

    final filtered = _memberContributions.where((item) {
      final due = item.updatedAt;
      if (startDate != null && due.isBefore(startDate)) return false;
      if (endDate != null && due.isAfter(endDate)) return false;
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

  double get _totalCurrentMonth {
    final now = DateTime.now();
    return _memberContributions
        .where((item) {
          final date = item.updatedAt;
          return date.year == now.year && date.month == now.month;
        })
        .fold<double>(0, (sum, c) => sum + c.amount);
  }

  int get _overdueCount {
    final now = DateTime.now();
    return _filteredItems.where((item) => !item.isPaid && item.updatedAt.isBefore(now)).length;
  }

  double get _upcomingAmount {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return _memberContributions
        .where((item) =>
            !item.isPaid &&
            item.updatedAt.isAfter(now) &&
            item.updatedAt.isBefore(limit))
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
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Inicio',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Filters Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filtros',
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
                                  _buildCheckbox('Solo vencidos', _onlyOverdue,
                                      (v) => setState(() => _onlyOverdue = v ?? false)),
                                  _buildCheckbox('Solo pendientes', _onlyPending,
                                      (v) => setState(() => _onlyPending = v ?? false)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // KPI Cards
                      GridView.count(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildKpiCard(
                            'Total mes actual',
                            _formatCurrency(_totalCurrentMonth),
                            Colors.blue,
                          ),
                          _buildKpiCard(
                            'Pagado',
                            _formatCurrency(_totals['paid'] ?? 0),
                            Colors.green,
                          ),
                          _buildKpiCard(
                            'Pendiente',
                            _formatCurrency(_totals['pending'] ?? 0),
                            Colors.orange,
                          ),
                          _buildKpiCard(
                            'Próximos 7 días',
                            _formatCurrency(_upcomingAmount),
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Overdue Count Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bills vencidos'),
                              const SizedBox(height: 8),
                              Text(
                                '$_overdueCount',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Contribuciones con fecha vencida',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
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
                              const Text(
                                'Resumen de tus contribuciones',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _filteredItems.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'No hay datos para los filtros seleccionados.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Monto')),
                                          DataColumn(label: Text('Estado')),
                                          DataColumn(label: Text('Fecha')),
                                        ],
                                        rows: _filteredItems
                                            .map(
                                              (item) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(_formatCurrency(item.amount)),
                                                  ),
                                                  DataCell(
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: item.isPaid
                                                            ? Colors.green.shade100
                                                            : Colors.orange.shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        item.isPaid
                                                            ? 'Pagado'
                                                            : 'Pendiente',
                                                        style: TextStyle(
                                                          color: item.isPaid
                                                              ? Colors.green.shade700
                                                              : Colors.orange.shade700,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _formatDate(item.updatedAt),
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
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: DropdownButton<String>(
        value: _dateRangeType,
        isExpanded: true,
        items: [
          const DropdownMenuItem(value: 'current', child: Text('Mes actual')),
          const DropdownMenuItem(value: 'last3', child: Text('Últimos 3 meses')),
          const DropdownMenuItem(value: 'custom', child: Text('Personalizado')),
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
    final options = ['all', ..._categories];
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: DropdownButton<String>(
        value: _categoryFilter,
        isExpanded: true,
        items: options
            .map((cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat == 'all' ? 'Todas' : cat),
            ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _categoryFilter = value);
          }
        },
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
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
