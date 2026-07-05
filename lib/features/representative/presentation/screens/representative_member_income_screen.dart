import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/core/utils/currency_utils.dart';
import 'package:budgetly_app/domain/entities/member_view_model.dart';
import 'package:budgetly_app/features/representative/data/household_member_api.dart';
import 'package:budgetly_app/features/representative/presentation/providers/household_members_provider.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/representative_dashboard_layout.dart';

class RepresentativeMemberIncomeScreen extends ConsumerStatefulWidget {
  const RepresentativeMemberIncomeScreen({super.key});

  @override
  ConsumerState<RepresentativeMemberIncomeScreen> createState() =>
      _RepresentativeMemberIncomeScreenState();
}

class _RepresentativeMemberIncomeScreenState
    extends ConsumerState<RepresentativeMemberIncomeScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _savingIds = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(MemberViewModel member) {
    final key = member.householdMemberId.isNotEmpty
        ? member.householdMemberId
        : member.userId;
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(
        text: member.income > 0 ? member.income.toStringAsFixed(2) : '',
      ),
    );
  }

  void _syncControllers(List<MemberViewModel> members) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final member in members) {
        final ctl = _controllerFor(member);
        final expected =
            member.income > 0 ? member.income.toStringAsFixed(2) : '';
        final key = member.householdMemberId.isNotEmpty
            ? member.householdMemberId
            : member.userId;
        if (ctl.text != expected && !_savingIds.contains(key)) {
          ctl.text = expected;
        }
      }
    });
  }

  Future<void> _saveIncome(MemberViewModel member, String currency) async {
    final l = context.l10n;
    if (member.householdMemberId.isEmpty) {
      _snack(l.t(
        'No se encontró el ID de membresía para guardar.',
        'Membership ID not found to save.',
      ));
      return;
    }

    final raw = _controllerFor(member).text.trim().replaceAll(',', '.');
    final income = double.tryParse(raw);
    if (income == null || income < 0) {
      _snack(l.t('Ingresa un monto válido (0 o mayor).', 'Enter a valid amount (0 or greater).'));
      return;
    }

    final key = member.householdMemberId;
    setState(() => _savingIds.add(key));
    try {
      final api = await HouseholdMemberApi.authorized();
      await api.updateMemberIncome(
        householdMemberId: member.householdMemberId,
        income: income,
      );
      ref.invalidate(householdMembersProvider);
      scheduleRepresentativeProviderRefresh(ref);
      if (mounted) {
        _snack(
          l.t(
            'Ingreso de ${member.displayName} guardado '
            '(${CurrencyUtils.formatSymbol(currency == 'USD')}'
            '${income.toStringAsFixed(2)}).',
            'Income for ${member.displayName} saved '
            '(${CurrencyUtils.formatSymbol(currency == 'USD')}'
            '${income.toStringAsFixed(2)}).',
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack(ApiFailure.wrap(e).messageEs);
    } finally {
      if (mounted) {
        setState(() => _savingIds.remove(key));
      }
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(householdMembersProvider);

    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repMemberIncomes,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: ApiFailure.wrap(error).messageEs,
          onRetry: () => ref.invalidate(householdMembersProvider),
        ),
        data: (data) {
          _syncControllers(data.members);
          final sym = CurrencyUtils.formatSymbol(data.currency == 'USD');

          if (data.members.isEmpty) {
            return _EmptyView(
              onGoMembers: () => context.go(AppRoutes.repMembers),
              l: l,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(householdMembersProvider);
              await ref.read(householdMembersProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  l.t('Registro de ingresos', 'Income registry'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.t(
                    'Ingreso mensual de cada persona del hogar. '
                    'Se guarda en la API y habilita repartos proporcionales.',
                    'Monthly income for each household member. '
                    'Saved to the API and enables proportional splits.',
                  ),
                  style: const TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: AppColors.dashBadgeBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: AppColors.dashBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.t('Total ingresos declarados', 'Total declared income'),
                                style: const TextStyle(
                                  color: AppColors.labelGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$sym${data.totalIncome.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          l.t('${data.members.length} miembros', '${data.members.length} members'),
                          style: const TextStyle(
                            color: AppColors.dashBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final member in data.members)
                  _MemberIncomeCard(
                    member: member,
                    currency: data.currency,
                    controller: _controllerFor(member),
                    isSaving: _savingIds.contains(
                      member.householdMemberId.isNotEmpty
                          ? member.householdMemberId
                          : member.userId,
                    ),
                    onSave: () => _saveIncome(member, data.currency),
                    l: l,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemberIncomeCard extends StatelessWidget {
  const _MemberIncomeCard({
    required this.member,
    required this.currency,
    required this.controller,
    required this.isSaving,
    required this.onSave,
    required this.l,
  });

  final MemberViewModel member;
  final String currency;
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final sym = CurrencyUtils.formatSymbol(currency == 'USD');
    final initial =
        member.displayName.isNotEmpty && member.displayName != 'Sin nombre'
            ? member.displayName.substring(0, 1).toUpperCase()
            : '?';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.dashBadgeGray,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          fontSize: 16,
                        ),
                      ),
                      if (member.email != null &&
                          member.email!.isNotEmpty &&
                          member.displayName != member.email) ...[
                        const SizedBox(height: 2),
                        Text(
                          member.email!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Chip(label: member.roleLabel),
                          if (member.status?.isNotEmpty == true)
                            _Chip(label: member.status!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              enabled: !isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.monthlyIncome,
                prefixText: sym,
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dashGreen,
                  foregroundColor: AppColors.white,
                ),
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(isSaving ? l.t('Guardando…', 'Saving…') : l.t('Guardar ingreso', 'Save income')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.dashBadgeGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.labelGray,
          fontWeight: FontWeight.w600,
        ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGray, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dashGreen,
                foregroundColor: AppColors.white,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onGoMembers, required this.l});

  final VoidCallback onGoMembers;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 56,
              color: AppColors.labelGray,
            ),
            const SizedBox(height: 16),
            Text(
              l.t('No hay miembros en este hogar', 'No members in this household'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.t(
                'Invita personas desde «Miembros» para registrar sus ingresos.',
                'Invite people from «Members» to register their incomes.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGray, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dashGreen,
                foregroundColor: AppColors.white,
              ),
              onPressed: onGoMembers,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l.t('Ir a Miembros', 'Go to Members')),
            ),
          ],
        ),
      ),
    );
  }
}
