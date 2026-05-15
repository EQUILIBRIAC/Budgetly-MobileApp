import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/representative_dashboard_layout.dart';

void _repSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<void> _copyToClipboard(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  _repSnack(context, 'Copiado al portapapeles');
}

RepresentativeData? _requireLoadedHousehold(WidgetRef ref, BuildContext context) {
  final data = ref.read(representativeProvider).valueOrNull;
  final hid = data?.activeHouseholdId.trim() ?? '';
  if (data == null || hid.isEmpty || data.household == null) {
    _repSnack(
      context,
      'Espera a que carguen los datos o crea un hogar en «Hogares».',
    );
    return null;
  }
  return data;
}

int? _parsedUserNumericId(AuthController auth) =>
    int.tryParse(auth.currentUser?.id.trim() ?? '');

String _memberRoleLabel(String? apiRole) {
  switch ((apiRole ?? '').toLowerCase()) {
    case 'representative':
      return 'Representante';
    case 'member':
      return 'Miembro';
    default:
      return apiRole?.isNotEmpty == true ? apiRole! : 'Miembro';
  }
}

Future<void> _openCreateBillSheet(
  BuildContext context,
  WidgetRef ref,
  RepresentativeData data,
) async {
  final auth = ref.read(authControllerProvider);
  final creator = _parsedUserNumericId(auth);
  if (creator == null) {
    _repSnack(
      context,
      'Tu cuenta no tiene un ID numérico de usuario para crear facturas.',
    );
    return;
  }

  final desc = TextEditingController();
  final amount = TextEditingController();
  DateTime paymentDue = DateTime.now().add(const Duration(days: 30));
  final hostContext = context;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva factura',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hogar: ${data.household?.name ?? ''}',
                    style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: desc,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej. Luz marzo',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      suffixText: data.currency == 'USD' ? 'USD' : 'PEN',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha de pago objetivo'),
                    subtitle: Text(
                      DateFormat.yMMMd(EnvConfig.localeDefault).format(paymentDue),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: paymentDue,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) setState(() => paymentDue = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dashGreen,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final v =
                          double.tryParse(amount.text.replaceAll(',', '.'));
                      if (desc.text.trim().isEmpty || v == null) {
                        _repSnack(
                          context,
                          'Completa descripción y un monto válido.',
                        );
                        return;
                      }
                      try {
                        await ref.read(representativeActionsProvider).createBill(
                              householdId: data.activeHouseholdId,
                              description: desc.text,
                              amount: v,
                              createdBy: creator,
                              paymentDate: paymentDue,
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        scheduleRepresentativeProviderRefresh(ref);
                        if (hostContext.mounted) {
                          _repSnack(hostContext, 'Factura registrada.');
                        }
                      } catch (e) {
                        if (!hostContext.mounted) return;
                        _repSnack(hostContext, ApiFailure.wrap(e).messageEs);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar factura'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    desc.dispose();
    amount.dispose();
  });
}

Future<void> _openAddMemberSheet(
  BuildContext context,
  WidgetRef ref,
  RepresentativeData data,
) async {
  final userIdCtl = TextEditingController();
  final incomeCtl = TextEditingController();
  String roleKey = 'member';
  final hostContext = context;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Invitar miembro',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.household?.name ?? 'Tu hogar',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600, color: AppColors.teal),
                  ),
                  Text(
                    'ID del hogar: ${data.activeHouseholdId}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'La otra persona debe tener cuenta en Budgetly y pasarte '
                    'su ID de usuario (en su app: Ajustes).',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.labelGray,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userIdCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID numérico del usuario',
                      hintText: 'Ej. 12',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: incomeCtl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Ingreso estimado (opcional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: roleKey,
                        onChanged: (v) => setState(() => roleKey = v ?? 'member'),
                        items: const [
                          DropdownMenuItem(
                            value: 'member',
                            child: Text('Es miembro del hogar'),
                          ),
                          DropdownMenuItem(
                            value: 'representative',
                            child: Text('Tiene rol de representante'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dashGreen,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await ref.read(representativeActionsProvider).createMember(
                              householdId: data.activeHouseholdId,
                              userId: userIdCtl.text.trim(),
                              role: roleKey,
                              income: double.tryParse(incomeCtl.text.trim()),
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        scheduleRepresentativeProviderRefresh(ref);
                        if (hostContext.mounted) {
                          _repSnack(hostContext, 'Miembro vinculado al hogar.');
                        }
                      } catch (e) {
                        if (!hostContext.mounted) return;
                        _repSnack(hostContext, ApiFailure.wrap(e).messageEs);
                      }
                    },
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Añadir miembro'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    userIdCtl.dispose();
    incomeCtl.dispose();
  });
}

Future<void> _openContributionSheet(
  BuildContext context,
  WidgetRef ref,
  RepresentativeData data,
) async {
  if (data.bills.isEmpty) {
    _repSnack(
      context,
      'Primero registra una factura en «Facturas».',
    );
    return;
  }

  var selected = data.bills.firstWhere(
    (b) => b.id.isNotEmpty,
    orElse: () => data.bills.first,
  );
  final desc = TextEditingController();
  DateTime deadline = DateTime.now().add(const Duration(days: 15));
  final items = data.bills.where((b) => b.id.isNotEmpty).toList();
  final hostContext = context;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          final safeItems = items.isNotEmpty ? items : data.bills;
          if (!safeItems.contains(selected)) {
            selected = safeItems.first;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva contribución',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elige la factura a repartir y avisa hasta cuándo deben pagar.',
                    style: TextStyle(fontSize: 13, color: AppColors.textGray),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Factura',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.labelGray,
                        ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<Bill>(
                    isExpanded: true,
                    value: selected,
                    items: safeItems
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b.description.length > 48
                                  ? '${b.description.substring(0, 48)}…'
                                  : b.description,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selected = v ?? selected;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: desc,
                    decoration: const InputDecoration(
                      labelText: 'Nota para el equipo (opcional)',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha límite'),
                    subtitle:
                        Text(DateFormat.yMMMd(EnvConfig.localeDefault).format(deadline)),
                    trailing: IconButton(
                      icon: const Icon(Icons.event_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) setState(() => deadline = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dashGreen,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await ref
                            .read(representativeActionsProvider)
                            .createContribution(
                              billId: selected.id,
                              householdId: data.activeHouseholdId,
                              description: desc.text,
                              deadlineForMembers: deadline,
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        scheduleRepresentativeProviderRefresh(ref);
                        if (hostContext.mounted) {
                          _repSnack(hostContext, 'Contribución registrada.');
                        }
                      } catch (e) {
                        if (!hostContext.mounted) return;
                        _repSnack(hostContext, ApiFailure.wrap(e).messageEs);
                      }
                    },
                    icon: const Icon(Icons.add_card),
                    label: const Text('Crear contribución'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => desc.dispose());
}

Future<void> _openEditBillSheet(
  BuildContext context,
  WidgetRef ref,
  RepresentativeData data,
  Bill bill,
) async {
  final desc = TextEditingController(text: bill.description);
  final amount = TextEditingController(text: bill.amount.toString());
  var paymentDue = bill.paymentDay ?? DateTime.now().add(const Duration(days: 30));
  final hostContext = context;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Editar factura',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: desc,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  TextField(
                    controller: amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      suffixText: data.currency == 'USD' ? 'USD' : 'PEN',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Día de pago'),
                    subtitle: Text(
                      DateFormat.yMMMd(EnvConfig.localeDefault).format(paymentDue),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: paymentDue,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) setState(() => paymentDue = picked);
                      },
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dashGreen,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: () async {
                      final v = double.tryParse(amount.text.replaceAll(',', '.'));
                      if (v == null || desc.text.trim().isEmpty) {
                        _repSnack(context, 'Datos incompletos.');
                        return;
                      }
                      try {
                        await ref.read(representativeActionsProvider).updateBill(
                              id: bill.id,
                              description: desc.text.trim(),
                              amount: v,
                              paymentDate: paymentDue,
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        scheduleRepresentativeProviderRefresh(ref);
                        if (hostContext.mounted) {
                          _repSnack(hostContext, 'Factura actualizada.');
                        }
                      } catch (e) {
                        if (!hostContext.mounted) return;
                        _repSnack(hostContext, ApiFailure.wrap(e).messageEs);
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    desc.dispose();
    amount.dispose();
  });
}

Future<void> _openEditHouseholdSheet(
  BuildContext context,
  WidgetRef ref,
  Household h,
  RepresentativeData data,
) async {
  final name = TextEditingController(text: h.name);
  final description = TextEditingController(text: h.description);
  final memberCount = TextEditingController(
    text: '${h.id == data.activeHouseholdId ? data.members.length : h.memberCount}',
  );
  var currency = h.currency;
  final hostContext = context;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Editar hogar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                  ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  TextField(
                    controller: memberCount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de miembros',
                      helperText: 'Según API PUT /house_hold/{id}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('PEN'),
                        selected: currency == 'PEN',
                        onSelected: (_) => setState(() => currency = 'PEN'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('USD'),
                        selected: currency == 'USD',
                        onSelected: (_) => setState(() => currency = 'USD'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dashGreen,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: () async {
                      final mc = int.tryParse(memberCount.text.trim());
                      if (name.text.trim().isEmpty || mc == null) {
                        _repSnack(context, 'Nombre y número de miembros válidos.');
                        return;
                      }
                      try {
                        await ref.read(representativeActionsProvider).updateHousehold(
                              id: h.id,
                              name: name.text,
                              description: description.text,
                              memberCount: mc,
                              currencyCode: currency,
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        scheduleRepresentativeProviderRefresh(ref);
                        if (hostContext.mounted) {
                          _repSnack(hostContext, 'Hogar actualizado.');
                        }
                      } catch (e) {
                        if (!hostContext.mounted) return;
                        _repSnack(hostContext, ApiFailure.wrap(e).messageEs);
                      }
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    name.dispose();
    description.dispose();
    memberCount.dispose();
  });
}

Future<void> _confirmDeleteBill(
  BuildContext context,
  WidgetRef ref,
  String billId,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar factura'),
      content: const Text('¿Eliminar esta factura del hogar? (DELETE /api/v1/bills/{id})'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(representativeActionsProvider).deleteBill(billId);
    if (!context.mounted) return;
    scheduleRepresentativeProviderRefresh(ref);
    _repSnack(context, 'Factura eliminada.');
  } catch (e) {
    if (!context.mounted) return;
    _repSnack(context, ApiFailure.wrap(e).messageEs);
  }
}

Future<void> _confirmDeleteMember(
  BuildContext context,
  WidgetRef ref,
  String membershipId,
) async {
  if (membershipId.isEmpty) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Quitar miembro'),
      content: const Text(
        'Quitar la vinculación de esta persona con el hogar '
        '(DELETE /api/v1/household_member/{id}).',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Quitar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(representativeActionsProvider).deleteHouseholdMember(membershipId);
    if (!context.mounted) return;
    scheduleRepresentativeProviderRefresh(ref);
    _repSnack(context, 'Miembro quitado del hogar.');
  } catch (e) {
    if (!context.mounted) return;
    _repSnack(context, ApiFailure.wrap(e).messageEs);
  }
}

Future<void> _confirmDeleteContribution(
  BuildContext context,
  WidgetRef ref,
  String contributionId,
) async {
  if (contributionId.isEmpty) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar aporte'),
      content: const Text('¿Eliminar esta contribución?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await ref.read(representativeActionsProvider).deleteContribution(contributionId);
    if (!context.mounted) return;
    scheduleRepresentativeProviderRefresh(ref);
    _repSnack(context, 'Contribución eliminada.');
  } catch (e) {
    if (!context.mounted) return;
    _repSnack(context, ApiFailure.wrap(e).messageEs);
  }
}

class RepresentativeDashboardScreen extends ConsumerWidget {
  const RepresentativeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(representativeProvider);
    final auth = ref.watch(authControllerProvider);
    final plan = auth.currentUser?.plan ?? 'FREE';
    final email = auth.currentUser?.email ?? '';
    final shortName =
        email.contains('@') ? email.split('@').first : 'equipo';

    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repDashboard,
      child: _AsyncRepView(
        state: state,
        onRetry: () => scheduleRepresentativeProviderRefresh(ref),
        builder: (data) {
          final sym = data.currency == 'USD' ? '\$' : 'S/';
          final hid = data.activeHouseholdId;
          final shortId =
              hid.length > 18 ? '${hid.substring(0, 10)}…' : hid;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido,',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.labelGray,
                              ),
                        ),
                        Text(
                          shortName,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Administra tu hogar con claridad',
                          style: TextStyle(color: AppColors.textGray, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dashBadgeBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Plan $plan',
                          style: const TextStyle(
                            color: AppColors.dashBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Material(
                        color: AppColors.dashBadgeGray,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => _copyToClipboard(context, hid),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.home_work_outlined,
                                  size: 14,
                                  color: AppColors.labelGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Hogar: $shortId',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _WebDashStat(
                      icon: Icons.people_outline,
                      label: 'Miembros',
                      value: '${data.members.length}',
                      hint: 'Equipo activo',
                      accent: AppColors.dashGreen,
                    ),
                    const SizedBox(width: 12),
                    _WebDashStat(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Gastos totales',
                      value: '$sym ${data.totalBills.toStringAsFixed(2)}',
                      hint: '${data.bills.length} facturas',
                      accent: AppColors.dashOrange,
                    ),
                    const SizedBox(width: 12),
                    _WebDashStat(
                      icon: Icons.bar_chart_rounded,
                      label: 'Aportes',
                      value: '${data.contributions.length}',
                      hint: 'Contribuciones',
                      accent: AppColors.dashPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Gestiona tu hogar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.02,
                children: [
                  _WebActionTile(
                    color: AppColors.dashBlue,
                    icon: Icons.group_outlined,
                    title: 'Miembros',
                    subtitle: 'Invita y administra',
                    onTap: () => context.go(AppRoutes.repMembers),
                  ),
                  _WebActionTile(
                    color: AppColors.dashOrange,
                    icon: Icons.receipt_long_outlined,
                    title: 'Gastos',
                    subtitle: 'Facturas del hogar',
                    onTap: () => context.go(AppRoutes.repBills),
                  ),
                  _WebActionTile(
                    color: AppColors.dashPurple,
                    icon: Icons.pie_chart_outline,
                    title: 'Aportes',
                    subtitle: 'Reparto de pagos',
                    onTap: () => context.go(AppRoutes.repContributions),
                  ),
                  _WebActionTile(
                    color: AppColors.dashCyan,
                    icon: Icons.settings_suggest_outlined,
                    title: 'Ajustes',
                    subtitle: 'Cuenta y preferencias',
                    onTap: () => context.go(AppRoutes.repSettings),
                  ),
                  _WebActionTile(
                    color: AppColors.dashGreen,
                    icon: Icons.home_work_outlined,
                    title: 'Hogares',
                    subtitle: 'Crear y elegir activo',
                    onTap: () => context.go(AppRoutes.repHouseholds),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: Icon(Icons.add, size: 18, color: AppColors.dashBlue),
                    label: const Text('Nueva factura'),
                    onPressed: () {
                      final d = _requireLoadedHousehold(ref, context);
                      if (d == null) return;
                      _openCreateBillSheet(context, ref, d);
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.person_add_alt, size: 18, color: AppColors.dashBlue),
                    label: const Text('Invitar miembro'),
                    onPressed: () {
                      final d = _requireLoadedHousehold(ref, context);
                      if (d == null) return;
                      _openAddMemberSheet(context, ref, d);
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.add_card, size: 18, color: AppColors.dashPurple),
                    label: const Text('Nueva contribución'),
                    onPressed: () {
                      final d = _requireLoadedHousehold(ref, context);
                      if (d == null) return;
                      _openContributionSheet(context, ref, d);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Facturas vencidas',
                value: '${data.overdueBills}',
                subtitle: 'Seguimiento pendiente',
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
        backgroundColor: AppColors.dashGreen,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo hogar'),
      ),
      child: _AsyncRepView(
        state: state,
        onRetry: () => scheduleRepresentativeProviderRefresh(ref),
        builder: (data) {
          final homes = data.ownedHouseholds.isNotEmpty
              ? data.ownedHouseholds
              : (data.household != null
                  ? <Household>[data.household!]
                  : <Household>[]);
          if (homes.isEmpty) {
            return _RepEmpty(
              message: 'Aún no tienes hogares registrados.',
              hint:
                  'Crea el primero con «Nuevo hogar». Luego podrás agregar facturas y miembros.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Text(
                'Administras ${homes.length} hogar${homes.length == 1 ? '' : 'es'}. '
                'El marcado como activo es el que usan las demás pestañas.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGray,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 16),
              ...homes.map((h) {
                final active = h.id == data.activeHouseholdId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: active ? AppColors.dashBlue : AppColors.borderGray,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  h.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                              if (active)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mint.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Activo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dashBlue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            h.description.isEmpty
                                ? 'Sin descripción'
                                : h.description,
                            style: const TextStyle(
                              color: AppColors.labelGray,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Moneda ${h.currency}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${h.memberCount} miembro${h.memberCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.dashOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            h.id,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.navy,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _copyToClipboard(context, h.id),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copiar ID del hogar'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (!active)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(representativeActionsProvider)
                                          .setPreferredHousehold(h.id);
                                      if (!context.mounted) return;
                                      scheduleRepresentativeProviderRefresh(ref);
                                      _repSnack(
                                        context,
                                        'Hogar activo actualizado.',
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      _repSnack(
                                        context,
                                        ApiFailure.wrap(e).messageEs,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                                  label: const Text('Usar este hogar'),
                                ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.dashBlue,
                                  foregroundColor: AppColors.white,
                                ),
                                onPressed: () => _openEditHouseholdSheet(
                                  context,
                                  ref,
                                  h,
                                  data,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Editar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
        onPressed: () {
          final d = _requireLoadedHousehold(ref, context);
          if (d == null) return;
          _openAddMemberSheet(context, ref, d);
        },
        backgroundColor: AppColors.dashGreen,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Agregar miembro'),
      ),
      child: _AsyncRepView(
        state: state,
        onRetry: () => scheduleRepresentativeProviderRefresh(ref),
        builder: (data) {
          if (data.members.isEmpty) {
            return _RepEmpty(
              message: 'Aquí aparecerán quienes comparten tus gastos.',
              hint:
                  'Cada persona necesita cuenta en Budgetly. Pídeles su '
                  'ID numérico (lo ven como miembro en Ajustes) y vínculos aquí.',
              action: FilledButton.icon(
                onPressed: () {
                  final loaded = _requireLoadedHousehold(ref, context);
                  if (loaded == null) return;
                  _openAddMemberSheet(context, ref, loaded);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dashGreen,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Invitar primer miembro'),
              ),
            );
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
                  isThreeLine: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(member.name ?? 'Sin nombre'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _memberRoleLabel(member.role),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID usuario: ${member.userId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.labelGray,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Copiar ID de usuario',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        color: AppColors.dashBlue,
                        onPressed: () =>
                            _copyToClipboard(context, member.userId),
                      ),
                      if (member.id.isNotEmpty)
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'del') {
                              await _confirmDeleteMember(
                                context,
                                ref,
                                member.id,
                              );
                            }
                          },
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                              value: 'del',
                              child: Text(
                                'Quitar del hogar',
                                style: TextStyle(color: AppColors.dangerRed),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final d = _requireLoadedHousehold(ref, context);
          if (d == null) return;
          _openCreateBillSheet(context, ref, d);
        },
        backgroundColor: AppColors.dashGreen,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva factura'),
      ),
      child: _AsyncRepView(
        state: state,
        onRetry: () => scheduleRepresentativeProviderRefresh(ref),
        builder: (data) {
          final sym = data.currency == 'USD' ? '\$' : 'S/';
          if (data.bills.isEmpty) {
            return _RepEmpty(
              message: 'Registra servicios, alquiler o cualquier gasto recurrente.',
              hint:
                  'Cuando existan facturas podrás crear contribuciones para repartirlas.',
              action: FilledButton.icon(
                onPressed: () {
                  final loaded = _requireLoadedHousehold(ref, context);
                  if (loaded == null) return;
                  _openCreateBillSheet(context, ref, loaded);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dashGreen,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Registrar factura'),
              ),
            );
          }
          final formatter = DateFormat('yyyy-MM-dd');
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                  leading: CircleAvatar(
                    backgroundColor: AppColors.dashOrange.withValues(alpha: 0.15),
                    child: const Icon(Icons.receipt_long_outlined, color: AppColors.dashOrange),
                  ),
                  title: Text(bill.description),
                  subtitle: Text(
                    'Vence: $dueDate'
                    '${bill.category != null && bill.category!.isNotEmpty ? ' · ${bill.category}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$sym ${bill.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.dashGreen,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (!context.mounted) return;
                          if (v == 'edit') {
                            await _openEditBillSheet(context, ref, data, bill);
                          } else if (v == 'del' && bill.id.isNotEmpty) {
                            await _confirmDeleteBill(context, ref, bill.id);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('Editar')),
                          const PopupMenuItem(
                            value: 'del',
                            child: Text('Eliminar', style: TextStyle(color: AppColors.dangerRed)),
                          ),
                        ],
                      ),
                    ],
                  ),
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
        onPressed: () {
          final d = _requireLoadedHousehold(ref, context);
          if (d == null) return;
          _openContributionSheet(context, ref, d);
        },
        backgroundColor: AppColors.dashGreen,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_card),
        label: const Text('Nueva contribución'),
      ),
      child: _AsyncRepView(
        state: state,
        onRetry: () => scheduleRepresentativeProviderRefresh(ref),
        builder: (data) {
          final sym = data.currency == 'USD' ? '\$' : 'S/';
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: AppColors.dashBadgeBlue,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () =>
                        _copyToClipboard(context, data.activeHouseholdId),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tag, size: 16, color: AppColors.dashBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hogar: ${data.activeHouseholdId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _WebDashStat(
                        icon: Icons.groups_outlined,
                        label: 'Miembros',
                        value: '${data.members.length}',
                        hint: 'Hogar activo',
                        accent: AppColors.dashBlue,
                      ),
                      const SizedBox(width: 10),
                      _WebDashStat(
                        icon: Icons.receipt_long_outlined,
                        label: 'Gastos base',
                        value: '$sym ${data.totalBills.toStringAsFixed(2)}',
                        hint: '${data.bills.length} facturas',
                        accent: AppColors.dashOrange,
                      ),
                      const SizedBox(width: 10),
                      _WebDashStat(
                        icon: Icons.volunteer_activism_outlined,
                        label: 'Contribuciones',
                        value: '${data.contributions.length}',
                        hint: 'Registradas',
                        accent: AppColors.dashPurple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (data.contributions.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(
                  child: _RepEmpty(
                    message:
                        'Las contribuciones reparten el pago de una factura.',
                    hint:
                        'Registra facturas en «Gastos» y vuelve a crear un aporte.',
                    action: FilledButton.icon(
                      onPressed: () {
                        final loaded = _requireLoadedHousehold(ref, context);
                        if (loaded == null) return;
                        _openContributionSheet(context, ref, loaded);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dashGreen,
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(Icons.add_card),
                      label: const Text('Crear contribución'),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
                        title:
                            Text(contribution.description ?? 'Sin descripción'),
                        subtitle: Text(
                          'Límite: ${DateFormat('d MMM yyyy', EnvConfig.localeDefault).format(contribution.deadlineForMembers)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Copiar ID',
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              color: AppColors.dashBlue,
                              onPressed: () =>
                                  _copyToClipboard(context, contribution.id),
                            ),
                            if (contribution.id.isNotEmpty)
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'del') {
                                    await _confirmDeleteContribution(
                                      context,
                                      ref,
                                      contribution.id,
                                    );
                                  }
                                },
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(
                                    value: 'del',
                                    child: Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        color: AppColors.dangerRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
  final hostContext = context;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Crear hogar'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del hogar',
                    hintText: 'Ej. Departamento centro',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Text(
                        'Moneda:',
                        style: TextStyle(color: AppColors.labelGray),
                      ),
                      const SizedBox(width: 12),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: currencyCode,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Soles (PEN)')),
                            DropdownMenuItem(value: 2, child: Text('Dólares (USD)')),
                          ],
                          onChanged: (value) =>
                              setState(() => currencyCode = value ?? 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dashGreen,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _repSnack(context, 'El nombre es obligatorio.');
                return;
              }
              try {
                await ref.read(representativeActionsProvider).createHousehold(
                      name: nameController.text,
                      description: descriptionController.text,
                      currencyCode: currencyCode,
                    );
                if (!context.mounted) return;
                Navigator.pop(context);
                scheduleRepresentativeProviderRefresh(ref);
                if (hostContext.mounted) {
                  _repSnack(hostContext, 'Hogar creado. Actualizando datos…');
                }
              } catch (e) {
                if (!hostContext.mounted) return;
                _repSnack(hostContext, ApiFailure.wrap(e).messageEs);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      );
    },
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    nameController.dispose();
    descriptionController.dispose();
  });
}

class _WebDashStat extends StatelessWidget {
  const _WebDashStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const Spacer(),
              Icon(
                Icons.north_east,
                size: 14,
                color: AppColors.placeholder,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.labelGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(fontSize: 10, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

class _WebActionTile extends StatelessWidget {
  const _WebActionTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.white.withValues(alpha: 0.25),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.white, size: 26),
                  const Spacer(),
                  Icon(Icons.more_horiz, color: AppColors.white.withValues(alpha: 0.85)),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.92),
                  fontSize: 12,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                      backgroundColor: AppColors.dashGreen,
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
  const _RepEmpty({
    required this.message,
    this.hint,
    this.action,
  });

  final String message;
  final String? hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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
            if (hint != null) ...[
              const SizedBox(height: 12),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.labelGray,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 22),
              action!,
            ],
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

