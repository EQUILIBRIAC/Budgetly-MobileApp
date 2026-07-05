import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/app/widgets/budgetly_logo.dart';
import 'package:budgetly_app/core/utils/api_value_parsers.dart';
import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';

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

  static const _navMeta = <({IconData icon, String route})>[
    (icon: Icons.dashboard_rounded, route: AppRoutes.repDashboard),
    (icon: Icons.home_work_outlined, route: AppRoutes.repHouseholds),
    (icon: Icons.group_outlined, route: AppRoutes.repMembers),
    (icon: Icons.account_balance_wallet_outlined, route: AppRoutes.repBills),
    (icon: Icons.bar_chart_rounded, route: AppRoutes.repContributions),
    (icon: Icons.tune_rounded, route: AppRoutes.repSettings),
  ];

  List<({String label, IconData icon, String route})> _nav(AppLocalizations l) {
    return [
      (label: l.home, icon: _navMeta[0].icon, route: _navMeta[0].route),
      (label: l.households, icon: _navMeta[1].icon, route: _navMeta[1].route),
      (label: l.members, icon: _navMeta[2].icon, route: _navMeta[2].route),
      (label: l.bills, icon: _navMeta[3].icon, route: _navMeta[3].route),
      (label: l.contributions, icon: _navMeta[4].icon, route: _navMeta[4].route),
      (label: l.settings, icon: _navMeta[5].icon, route: _navMeta[5].route),
    ];
  }

  String _initials(String? email) {
    if (email == null || email.trim().isEmpty) return 'US';
    final part = email.trim().split('@').first;
    if (part.length >= 2) return part.substring(0, 2).toUpperCase();
    return part.isNotEmpty ? part[0].toUpperCase() : 'US';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final navItems = _nav(l);
    final auth = ref.watch(authControllerProvider);
    final email = normalizeApiEmail(auth.currentUser?.email ?? '');
    final routeIdx = navItems.indexWhere((e) => e.route == currentRoute);
    final idx = routeIdx >= 0 ? routeIdx : 0;

    void go(String route) {
      final scaffold = Scaffold.maybeOf(context);
      if (scaffold?.isDrawerOpen ?? false) {
        scaffold!.closeDrawer();
      }
      context.go(route);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: l.menu,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          representativeScreenTitle(context, currentRoute),
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
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
            tooltip: l.alertsComingSoon,
            onPressed: () {},
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.notifications_none_rounded),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.dashGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BudgetlyLogo(size: 44, showWordmark: true),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.dashBadgeBlue,
                          child: Text(
                            _initials(email),
                            style: const TextStyle(
                              color: AppColors.dashBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email.isEmpty ? l.representativeRole : email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dashBadgeGray,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l.representativeRole,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.labelGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Text(
                  l.generalSection,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.labelGray,
                  ),
                ),
              ),
              for (final item in navItems.take(5))
                _DrawerTile(
                  icon: item.icon,
                  label: item.label,
                  selected: currentRoute == item.route,
                  onTap: () => go(item.route),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Text(
                  l.toolsSection,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.labelGray,
                  ),
                ),
              ),
              _DrawerTile(
                icon: Icons.payments_outlined,
                label: l.memberIncomes,
                selected: currentRoute == AppRoutes.repMemberIncomes,
                onTap: () => go(AppRoutes.repMemberIncomes),
              ),
              _DrawerTile(
                icon: Icons.settings_outlined,
                label: l.settings,
                selected: currentRoute == AppRoutes.repSettings,
                onTap: () => go(AppRoutes.repSettings),
              ),
              _DrawerTile(
                icon: Icons.person_outline,
                label: l.profile,
                selected: false,
                onTap: () => go(AppRoutes.repSettings),
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.dangerRed),
                title: Text(
                  l.logout,
                  style: const TextStyle(
                    color: AppColors.dangerRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: child,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: AppColors.dashBlue.withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final sel = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? AppColors.dashBlue : AppColors.textGray,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final sel = states.contains(WidgetState.selected);
              return IconThemeData(
                color: sel ? AppColors.dashBlue : AppColors.labelGray,
                size: 22,
              );
            }),
          ),
        ),
        child: NavigationBar(
          height: 72,
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go(navItems[i].route),
          destinations: [
            for (final item in navItems)
              NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.dashBlue : AppColors.labelGray,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.dashBlue : AppColors.navy,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.dashBlue,
      selectedTileColor: AppColors.dashBadgeBlue.withValues(alpha: 0.55),
      onTap: onTap,
    );
  }
}
