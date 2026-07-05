import 'package:flutter/material.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_dashboard_layout.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_no_household_view.dart';
import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_page_styles.dart';
import 'package:intl/intl.dart';

/// Gastos del hogar en solo lectura para el segmento miembro.
class MemberBillsScreen extends StatefulWidget {
  const MemberBillsScreen({super.key});

  @override
  State<MemberBillsScreen> createState() => _MemberBillsScreenState();
}

class _MemberBillsScreenState extends State<MemberBillsScreen> {
  bool _isLoading = true;
  bool _needsHousehold = false;
  String _error = '';
  List<Bill> _bills = [];
  String _currency = 'PEN';

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

      final householdId = user['householdId']?.toString().trim() ?? '';
      if (householdId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _needsHousehold = true;
          _isLoading = false;
        });
        return;
      }

      final http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        http.setToken(token);
      }

      final householdResp = await http.get(ApiPaths.houseHold(householdId));
      final householdMap = ApiJson.objectData(householdResp);
      if (householdMap != null) {
        final household = Household.fromJson(householdMap);
        _currency = household.currency;
      }

      final billsResp = await http.get(ApiPaths.billsByHousehold(householdId));
      final bills = ApiJson.listDataFlexible(billsResp)
          .map((json) => Bill.fromJson(json))
          .toList();

      if (!mounted) return;
      setState(() {
        _bills = bills;
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

  String _formatCurrency(double value) {
    final sym = _currency == 'USD' ? '\$' : 'S/';
    return '$sym ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final formatter = DateFormat('dd/MM/yyyy');

    return MemberDashboardLayout(
      currentRoute: 'member-bills',
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _needsHousehold
                  ? MemberNoHouseholdView(onRetry: _loadData)
                  : _error.isNotEmpty
                      ? SizedBox(
                          height: 400,
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
                              l.householdBills,
                              style: MemberPageStyles.pageTitle(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.householdBillsReadOnly,
                              style: MemberPageStyles.bodyMuted(context),
                            ),
                            const SizedBox(height: 20),
                            if (_bills.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    l.noBillsYet,
                                  ),
                                ),
                              )
                            else
                              ..._bills.map((bill) {
                                final due = bill.paymentDay == null
                                    ? 'Sin fecha'
                                    : formatter.format(bill.paymentDay!);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12),
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    title: Text(
                                      bill.description,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Vence: $due'
                                      '${bill.category != null && bill.category!.isNotEmpty ? ' · ${bill.category}' : ''}',
                                    ),
                                    trailing: Text(
                                      _formatCurrency(bill.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
        ),
      ),
    );
  }
}
