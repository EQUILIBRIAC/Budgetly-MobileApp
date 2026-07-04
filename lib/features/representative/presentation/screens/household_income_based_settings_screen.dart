import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/core/utils/currency_utils.dart';
import 'package:budgetly_app/features/representative/presentation/providers/household_settings_provider.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/representative_dashboard_layout.dart';

class HouseholdIncomeBasedSettingsScreen extends ConsumerStatefulWidget {
  const HouseholdIncomeBasedSettingsScreen({super.key});

  @override
  ConsumerState<HouseholdIncomeBasedSettingsScreen> createState() =>
      _HouseholdIncomeBasedSettingsScreenState();
}

class _HouseholdIncomeBasedSettingsScreenState
    extends ConsumerState<HouseholdIncomeBasedSettingsScreen> {
  bool? _incomeBasedEnabled;
  bool _saving = false;

  Future<void> _save(HouseholdSettingsData data) async {
    final enabled = _incomeBasedEnabled ?? data.incomeBasedEnabled;

    if (enabled && data.totalIncome <= 0) {
      _showSnack('Registra ingresos antes de activar IncomeBased');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(householdSettingsActionsProvider).saveIncomeBasedConfiguration(
            householdId: data.householdId,
            enabled: enabled,
          );
      if (!mounted) return;
      _showSnack('Configuración guardada.');
    } catch (e) {
      if (!mounted) return;
      _showSnack(ApiFailure.wrap(e).messageEs);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(householdSettingsProvider);

    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repHouseholdIncomeSettings,
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: ApiFailure.wrap(e).messageEs,
          onRetry: () => ref.invalidate(householdSettingsProvider),
        ),
        data: (data) {
          _incomeBasedEnabled ??= data.incomeBasedEnabled;
          final enabled = _incomeBasedEnabled!;
          final sym = CurrencyUtils.formatSymbol(data.currency == 'USD');
          final profiles = data.members;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reparto por ingreso',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Activa IncomeBased para repartir cada factura de forma '
                  'proporcional al ingreso mensual de cada miembro.',
                  style: TextStyle(color: AppColors.textGray, height: 1.35),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderGray),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Reparto proporcional por ingreso (IncomeBased)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      enabled
                          ? 'Las facturas se repartirán según el % de ingreso.'
                          : 'Reparto igualitario (Even) entre miembros activos.',
                    ),
                    value: enabled,
                    activeThumbColor: AppColors.dashGreen,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _incomeBasedEnabled = v),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Resumen de miembros',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingreso total del hogar: $sym${data.totalIncome.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textGray),
                ),
                const SizedBox(height: 12),
                if (profiles.isEmpty)
                  const Text('No hay miembros activos en este hogar.')
                else
                  ...profiles.map(
                    (m) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.borderGray),
                      ),
                      child: ListTile(
                        title: Text(m.name),
                        subtitle: Text(
                          'Ingreso mensual: $sym${m.income.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          '${m.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.dashGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : () => _save(data),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dashGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Guardar configuración'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
