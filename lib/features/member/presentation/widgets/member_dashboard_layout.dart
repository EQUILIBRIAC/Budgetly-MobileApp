import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';

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
  final List<({String label, String icon, String route})> _menuItems = [
    (label: 'Inicio', icon: 'home', route: 'member-dashboard'),
    (label: 'Mis aportes', icon: 'check_square', route: 'member-contributions'),
    (label: 'Estado del hogar', icon: 'file', route: 'member-household-status'),
    (label: 'Buscar hogar', icon: 'search', route: 'member-search-household'),
    (label: 'Configuración', icon: 'sliders_h', route: 'member-settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: AppColors.lightGray,
          width: double.infinity,
          height: double.infinity,
          child: widget.child,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.borderGray, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Menu Items (Lazy Row)
                ..._menuItems.map((item) {
                  final isActive = widget.currentRoute == item.route;
                  return _buildNavItem(
                    label: item.label,
                    icon: item.icon,
                    route: item.route,
                    isActive: isActive,
                  );
                }),

                // Spacer
                const SizedBox(width: 8),

                // Logout Button
                _buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required String icon,
    required String route,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        switch (route) {
          case 'member-dashboard':
            context.go(AppRoutes.memberDashboard);
            break;
          case 'member-contributions':
            context.go(AppRoutes.memberContributions);
            break;
          case 'member-household-status':
            context.go(AppRoutes.memberHouseholdStatus);
            break;
          case 'member-search-household':
            context.go(AppRoutes.memberSearchHousehold);
            break;
          case 'member-settings':
            context.go(AppRoutes.memberSettings);
            break;
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.teal.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: AppColors.teal, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? AppColors.teal : AppColors.lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  _getIconData(icon),
                  size: 18,
                  color: isActive ? AppColors.white : AppColors.labelGray,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.teal : AppColors.textGray,
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

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.logout,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Salir',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
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

  IconData _getIconData(String iconName) {
    final icons = {
      'home': Icons.home,
      'check_square': Icons.check_box,
      'file': Icons.description,
      'search': Icons.search,
      'sliders_h': Icons.settings,
    };
    return icons[iconName] ?? Icons.circle;
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
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

