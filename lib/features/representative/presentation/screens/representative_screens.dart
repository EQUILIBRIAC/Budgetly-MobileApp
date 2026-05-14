import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';

class RepresentativeDashboardLayout extends ConsumerWidget {
  const RepresentativeDashboardLayout({
    required this.child,
    required this.currentRoute,
    this.floatingActionButton,
    super.key,
  });

  final Widget child;
  final String currentRoute;
  final Widget? floatingActionButton;

  static const _items = <({String label, IconData icon, String route})>[
    (label: 'Dashboard', icon: Icons.dashboard, route: AppRoutes.repDashboard),
    (label: 'Hogares', icon: Icons.home_work_outlined, route: AppRoutes.repHouseholds),
    (label: 'Miembros', icon: Icons.group_outlined, route: AppRoutes.repMembers),
    (label: 'Facturas', icon: Icons.receipt_long_outlined, route: AppRoutes.repBills),
    (label: 'Aportes', icon: Icons.payments_outlined, route: AppRoutes.repContributions),
    (label: 'Ajustes', icon: Icons.settings_outlined, route: AppRoutes.repSettings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeIdx =
        _items.indexWhere((item) => item.route == currentRoute);
    final navSelectedIndex = routeIdx >= 0 ? routeIdx : 0;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(
          'Panel representante',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderGray),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            color: AppColors.teal,
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: AppColors.mint.withValues(alpha: 0.45),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final sel = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? AppColors.teal : AppColors.textGray,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final sel = states.contains(WidgetState.selected);
              return IconThemeData(
                color: sel ? AppColors.teal : AppColors.labelGray,
                size: 22,
              );
            }),
          ),
        ),
        child: NavigationBar(
          height: 72,
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          selectedIndex: navSelectedIndex,
          onDestinationSelected: (index) => context.go(_items[index].route),
          destinations: _items
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class RepresentativeDashboardScreen extends ConsumerWidget {
  const RepresentativeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(representativeProvider);
    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repDashboard,
      child: _AsyncRepView(
        state: state,
        onRetry: () => ref.refresh(representativeProvider),
        builder: (data) {
          final currencySymbol = data.currency == 'USD' ? '\$' : 'S/';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _MetricCard(
                title: 'Total facturas',
                value: '${data.bills.length}',
                subtitle: 'Facturas registradas',
              ),
              _MetricCard(
                title: 'Monto total',
                value: '$currencySymbol ${data.totalBills.toStringAsFixed(2)}',
                subtitle: 'Suma de todas las facturas',
              ),
              _MetricCard(
                title: 'Miembros activos',
                value: '${data.members.length}',
                subtitle: 'Miembros del hogar',
              ),
              _MetricCard(
                title: 'Facturas vencidas',
                value: '${data.overdueBills}',
                subtitle: 'Requieren atención',
              ),
            ],
          );
        },
      ),
    );
  }
}

class RepresentativeHouseholdsScreen extends ConsumerWidget {
  const RepresentativeHouseholdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(representativeProvider);
    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repHouseholds,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateHouseholdDialog(context, ref),
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo hogar'),
      ),
      child: _AsyncRepView(
        state: state,
        onRetry: () => ref.refresh(representativeProvider),
        builder: (data) {
          final household = data.household;
          if (household == null) {
            return const _RepEmpty(message: 'No se encontró información del hogar.');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              _MetricCard(
                title: household.name,
                value: household.currency,
                subtitle: household.description.isEmpty
                    ? 'Sin descripción'
                    : household.description,
              ),
            ],
          );
        },
      ),
    );
  }
}

class RepresentativeMembersScreen extends ConsumerWidget {
  const RepresentativeMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(representativeProvider);
    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repMembers,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMemberDialog(context, ref),
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Agregar miembro'),
      ),
      child: _AsyncRepView(
        state: state,
        onRetry: () => ref.refresh(representativeProvider),
        builder: (data) {
          if (data.members.isEmpty) {
            return const _RepEmpty(message: 'Aún no hay miembros registrados.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: data.members.length,
            itemBuilder: (context, index) {
              final member = data.members[index];
              return Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderGray),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(member.name ?? 'Sin nombre'),
                  subtitle: Text(member.role ?? 'member'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RepresentativeBillsScreen extends ConsumerWidget {
  const RepresentativeBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(representativeProvider);
    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repBills,
      child: _AsyncRepView(
        state: state,
        onRetry: () => ref.refresh(representativeProvider),
        builder: (data) {
          if (data.bills.isEmpty) {
            return const _RepEmpty(message: 'No hay facturas por mostrar.');
          }
          final formatter = DateFormat('yyyy-MM-dd');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: data.bills.length,
            itemBuilder: (context, index) {
              final bill = data.bills[index];
              final dueDate = bill.paymentDay == null
                  ? 'Sin fecha'
                  : formatter.format(bill.paymentDay!);
              return Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderGray),
                ),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(bill.description),
                  subtitle: Text('Vence: $dueDate'),
                  trailing: Text(bill.amount.toStringAsFixed(2)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RepresentativeContributionsScreen extends ConsumerWidget {
  const RepresentativeContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(representativeProvider);
    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repContributions,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateContributionDialog(context, ref),
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_card),
        label: const Text('Nueva contribución'),
      ),
      child: _AsyncRepView(
        state: state,
        onRetry: () => ref.refresh(representativeProvider),
        builder: (data) {
          if (data.contributions.isEmpty) {
            return const _RepEmpty(message: 'No hay contribuciones registradas.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: data.contributions.length,
            itemBuilder: (context, index) {
              final contribution = data.contributions[index];
              return Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderGray),
                ),
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(contribution.description ?? 'Sin descripción'),
                  subtitle: Text('ID: ${contribution.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _showCreateHouseholdDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  int currencyCode = 1;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Crear hogar'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              DropdownButton<int>(
                value: currencyCode,
                onChanged: (value) => setState(() => currencyCode = value ?? 1),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('PEN')),
                  DropdownMenuItem(value: 2, child: Text('USD')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(representativeActionsProvider).createHousehold(
                      name: nameController.text,
                      description: descriptionController.text,
                      currencyCode: currencyCode,
                    );
                ref.invalidate(representativeProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hogar creado correctamente.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      );
    },
  );
}

Future<void> _showCreateMemberDialog(BuildContext context, WidgetRef ref) async {
  final householdController = TextEditingController();
  final userController = TextEditingController();
  final incomeController = TextEditingController();
  String role = 'member';

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Agregar miembro'),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: householdController,
              decoration: const InputDecoration(labelText: 'Household ID'),
            ),
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            TextField(
              controller: incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ingreso (opcional)'),
            ),
            DropdownButton<String>(
              value: role,
              onChanged: (value) => setState(() => role = value ?? 'member'),
              items: const [
                DropdownMenuItem(value: 'member', child: Text('member')),
                DropdownMenuItem(value: 'representative', child: Text('representative')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(representativeActionsProvider).createMember(
                    householdId: householdController.text.trim(),
                    userId: userController.text.trim(),
                    role: role,
                    income: double.tryParse(incomeController.text.trim()),
                  );
              ref.invalidate(representativeProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Miembro agregado correctamente.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<void> _showCreateContributionDialog(BuildContext context, WidgetRef ref) async {
  final billController = TextEditingController();
  final householdController = TextEditingController();
  final descriptionController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nueva contribución'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: billController,
            decoration: const InputDecoration(labelText: 'Bill ID'),
          ),
          TextField(
            controller: householdController,
            decoration: const InputDecoration(labelText: 'Household ID'),
          ),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(representativeActionsProvider).createContribution(
                    billId: billController.text.trim(),
                    householdId: householdController.text.trim(),
                    description: descriptionController.text,
                  );
              ref.invalidate(representativeProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contribución creada correctamente.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          child: const Text('Crear'),
        ),
      ],
    ),
  );
}

class RepresentativeSettingsScreen extends ConsumerWidget {
  const RepresentativeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repSettings,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.borderGray),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tu cuenta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.currentUser?.email ?? '-',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await ref.read(authControllerProvider).signOut();
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AsyncRepView extends StatelessWidget {
  const _AsyncRepView({
    required this.state,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<RepresentativeData> state;
  final Widget Function(RepresentativeData data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    ApiFailure.wrap(error).messageEs,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: builder,
    );
  }
}

class _RepEmpty extends StatelessWidget {
  const _RepEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 56,
              color: AppColors.labelGray.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderGray),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.labelGray,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

