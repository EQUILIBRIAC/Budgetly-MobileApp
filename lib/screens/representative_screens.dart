import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../app/app_router.dart';
import '../app/app_routes.dart';
import '../providers/representative_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel representante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _items.indexWhere((item) => item.route == currentRoute),
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
            padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(16),
            itemCount: data.members.length,
            itemBuilder: (context, index) {
              final member = data.members[index];
              return Card(
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
            padding: const EdgeInsets.all(16),
            itemCount: data.bills.length,
            itemBuilder: (context, index) {
              final bill = data.bills[index];
              final dueDate = bill.paymentDay == null
                  ? 'Sin fecha'
                  : formatter.format(bill.paymentDay!);
              return Card(
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
            padding: const EdgeInsets.all(16),
            itemCount: data.contributions.length,
            itemBuilder: (context, index) {
              final contribution = data.contributions[index];
              return Card(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Correo: ${auth.currentUser?.email ?? '-'}'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
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
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
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
    return Center(child: Text(message));
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
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
