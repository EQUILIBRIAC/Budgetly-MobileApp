import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/contribution_model.dart';
import '../models/household_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';
import 'member_dashboard_layout.dart';

class MemberContributionsScreen extends StatefulWidget {
  const MemberContributionsScreen({super.key});

  @override
  State<MemberContributionsScreen> createState() =>
      _MemberContributionsScreenState();
}

class _MemberContributionsScreenState extends State<MemberContributionsScreen> {
  late final TextEditingController _incomeController;
  bool _isLoading = true;
  bool _isSavingIncome = false;
  String _error = '';
  String _success = '';

  List<HouseholdMember> _members = [];
  List<MemberContribution> _memberContributions = [];
  String _memberId = '';
  double _currentIncome = 0.0;

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
    try {
      final userStr = await _getStoredUser();
      if (userStr == null) throw Exception('Usuario no encontrado');

      final user = userStr;
      final householdId = _toString(user['householdId']);
      if (householdId == null || householdId.isEmpty) {
        throw Exception('Información de usuario incompleta');
      }

      final httpService = HttpService(baseUrl: ApiConfig.baseUrl);
      
      // Set token on the service
      final token = await StorageService.getToken();
      if (token != null) {
        httpService.setToken(token);
      }

      final [memberList, contributions, memberContribs, bills] = await Future.wait([
        _fetchMembers(httpService, householdId),
        _fetchContributions(httpService, householdId),
        _fetchMemberContributions(httpService),
        _fetchBills(httpService, householdId),
      ]);

      setState(() {
        _members = memberList as List<HouseholdMember>;
        _memberContributions = memberContribs as List<MemberContribution>;

        // Find current member - handle both String and int IDs
        final userId = _toString(user['id']);
        final member = _members.firstWhere(
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

        _memberId = member.id;
        _currentIncome = member.income ?? 0.0;
        _incomeController.text = _currentIncome.toStringAsFixed(2);

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
      final response = await httpService.get(
        '/api/v1/household/$householdId/members',
      );
      final list = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map((json) => HouseholdMember.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Contribution>> _fetchContributions(
    HttpService httpService,
    String householdId,
  ) async {
    try {
      final response = await httpService.get(
        '/api/v1/household/$householdId/contributions',
      );
      final list = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map((json) => Contribution.fromJson(json)).toList();
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
      final response = await httpService.get(
        '/api/v1/household/$householdId/bills',
      );
      final list = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return list.map((json) => Bill.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> _getStoredUser() async {
    // Use real StorageService to get stored user data
    try {
      final user = await StorageService.getUser();
      if (user == null) return null;
      return user;
    } catch (e) {
      print('Error getting stored user: $e');
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
      final httpService = HttpService(baseUrl: ApiConfig.baseUrl);
      await httpService.post(
        '/api/v1/household-member/$_memberId',
        body: {
          'income': double.parse(_incomeController.text),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _currentIncome = double.parse(_incomeController.text);
        _success = 'Ingreso actualizado correctamente.';
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

  Map<String, double> get _totals {
    final myContributions = _memberContributions
        .where((c) => c.memberId == _memberId)
        .toList();

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
    return MemberDashboardLayout(
      currentRoute: 'member-contributions',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _error.isNotEmpty
                ? Center(
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Mis aportes',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
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
                              const Text(
                                'Ingreso mensual',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Este dato solo es visible para ti y nos permite estimar metas personalizadas.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
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
                                        hintText: 'S/ 0.00',
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
                                    label: const Text('Guardar'),
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
                              const Text(
                                'Tus aportes',
                                style: TextStyle(
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
                                    'Total asignado',
                                    _formatCurrency(_totals['assigned'] ?? 0),
                                    Colors.blue,
                                  ),
                                  _buildPill(
                                    'Pagado',
                                    _formatCurrency(_totals['paid'] ?? 0),
                                    Colors.green,
                                  ),
                                  _buildPill(
                                    'Pendiente',
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
                              const Text(
                                'Contribuciones registradas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _memberContributions.isEmpty
                                  ? const Text(
                                      'No tienes contribuciones asignadas aún.',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Gasto')),
                                          DataColumn(label: Text('Monto')),
                                          DataColumn(label: Text('Estado')),
                                        ],
                                        rows: _memberContributions
                                            .map(
                                              (contrib) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text('Gasto #${contrib.id.substring(0, 8)}'),
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
                                                            ? 'Pagado'
                                                            : 'Pendiente',
                                                        style: TextStyle(
                                                          color: contrib.isPaid
                                                              ? Colors.green.shade700
                                                              : Colors.orange.shade700,
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
                            ],
                          ),
                        ),
                      ),
                    ],
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
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
