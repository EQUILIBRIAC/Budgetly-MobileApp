import 'package:flutter/material.dart';

class MemberDashboardLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MemberDashboardLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MemberDashboardLayout> createState() => _MemberDashboardLayoutState();
}

class _MemberDashboardLayoutState extends State<MemberDashboardLayout> {
  bool _sidebarCollapsed = false;

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
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarCollapsed ? 92 : 280,
            color: Colors.white,
            child: Column(
              children: [
                // Sidebar Header
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_sidebarCollapsed)
                        Text(
                          'Budgetly',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _sidebarCollapsed ? Icons.menu : Icons.menu,
                          color: const Color(0xFF0F172A),
                        ),
                        onPressed: () {
                          setState(() {
                            _sidebarCollapsed = !_sidebarCollapsed;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    children: _menuItems.map((item) {
                      final isActive = widget.currentRoute == item.route;
                      return _buildMenuItem(
                        label: item.label,
                        icon: item.icon,
                        route: item.route,
                        isActive: isActive,
                        isCollapsed: _sidebarCollapsed,
                      );
                    }).toList(),
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: _logout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                        if (!_sidebarCollapsed)
                          const SizedBox(width: 12),
                        if (!_sidebarCollapsed)
                          const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required String icon,
    required String route,
    required bool isActive,
    required bool isCollapsed,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacementNamed(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4FACFE) : const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  _getIconData(icon),
                  size: 16,
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
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

  void _performLogout() {
    // Clear localStorage equivalent (SharedPreferences)
    Navigator.of(context).pushReplacementNamed('login');
  }
}
