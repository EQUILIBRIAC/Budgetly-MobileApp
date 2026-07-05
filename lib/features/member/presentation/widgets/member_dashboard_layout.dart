import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/widgets/budgetly_logo.dart';
import 'package:budgetly_app/core/utils/api_value_parsers.dart';
import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:budgetly_app/app/router/app_routes.dart';

class MemberDashboardLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const MemberDashboardLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<MemberDashboardLayout> createState() =>
      _MemberDashboardLayoutState();
}

class _MemberDashboardLayoutState extends ConsumerState<MemberDashboardLayout> {
  static const _navMeta = <({IconData icon, String routeKey, String path})>[
    (
      icon: Icons.home_outlined,
      routeKey: 'member-dashboard',
      path: AppRoutes.memberDashboard,
    ),
    (
      icon: Icons.receipt_long_outlined,
      routeKey: 'member-bills',
      path: AppRoutes.memberBills,
    ),
    (
      icon: Icons.check_box_outlined,
      routeKey: 'member-contributions',
      path: AppRoutes.memberContributions,
    ),
    (
      icon: Icons.settings_outlined,
      routeKey: 'member-settings',
      path: AppRoutes.memberSettings,
    ),
  ];

  List<({String label, IconData icon, String routeKey, String path})> _nav(
    AppLocalizations l,
  ) {
    return [
      (
        label: l.home,
        icon: _navMeta[0].icon,
        routeKey: _navMeta[0].routeKey,
        path: _navMeta[0].path,
      ),
      (
        label: l.bills,
        icon: _navMeta[1].icon,
        routeKey: _navMeta[1].routeKey,
        path: _navMeta[1].path,
      ),
      (
        label: l.myContributions,
        icon: _navMeta[2].icon,
        routeKey: _navMeta[2].routeKey,
        path: _navMeta[2].path,
      ),
      (
        label: l.settings,
        icon: _navMeta[3].icon,
        routeKey: _navMeta[3].routeKey,
        path: _navMeta[3].path,
      ),
    ];
  }

  String _initials(String email) {
    if (email.isEmpty) return 'MB';
    final part = email.split('@').first;
    if (part.length >= 2) return part.substring(0, 2).toUpperCase();
    return part.isNotEmpty ? part[0].toUpperCase() : 'MB';
  }

  void _go(String path) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
    }
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final navItems = _nav(l);
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final auth = ref.watch(authControllerProvider);
    final email = normalizeApiEmail(auth.currentUser?.email ?? '');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: l.menu,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const BudgetlyLogo(size: 28, iconOnly: true),
            const SizedBox(width: 10),
            Text(
              memberScreenTitle(context, widget.currentRoute),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
      ),
      drawer: Drawer(
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
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
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            _initials(email),
                            style: TextStyle(
                              color: scheme.onPrimaryContainer,
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
                                email.isEmpty ? l.memberRole : email,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
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
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l.memberRole,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
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
              Divider(height: 1, color: scheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Text(
                  l.menuSection,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final item in navItems)
                _MemberDrawerTile(
                  icon: item.icon,
                  label: item.label,
                  selected: widget.currentRoute == item.routeKey,
                  onTap: () => _go(item.path),
                ),
              const Spacer(),
              Divider(height: 1, color: scheme.outlineVariant),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: scheme.error),
                title: Text(
                  l.logout,
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: bg,
          width: double.infinity,
          height: double.infinity,
          child: widget.child,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: navItems.map((item) {
              final isActive = widget.currentRoute == item.routeKey;
              return Expanded(
                child: _buildNavItem(
                  context: context,
                  label: item.label,
                  icon: item.icon,
                  path: item.path,
                  isActive: isActive,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String path,
    required bool isActive,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => _go(path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: Text(
              l.logoutAction,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    await ref.read(authControllerProvider).signOut();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }
}

class _MemberDrawerTile extends StatelessWidget {
  const _MemberDrawerTile({
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
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}
