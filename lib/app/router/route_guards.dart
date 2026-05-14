import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'app_routes.dart';
/// Reglas centralizadas de navegación según sesión y rol.
String? resolveAuthRedirect({
  required AuthController auth,
  required GoRouterState state,
}) {
  final isAuth = auth.isAuthenticated;
  final isLoading = auth.status == AuthStatus.loading;
  final location = state.matchedLocation;

  if (isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final isPublic = location == AppRoutes.login ||
      location == AppRoutes.signup ||
      location == AppRoutes.forgotPassword;

  if (!isAuth) {
    return isPublic ? null : AppRoutes.login;
  }

  if (isPublic || location == AppRoutes.splash) {
    return auth.role == 'member'
        ? AppRoutes.memberDashboard
        : AppRoutes.repDashboard;
  }

  final isMemberPath = location.startsWith('/member/');
  final isRepPath = location.startsWith('/rep/');

  if (auth.role == 'member' && isRepPath) {
    return AppRoutes.memberDashboard;
  }
  if (auth.role != 'member' && isMemberPath) {
    return AppRoutes.repDashboard;
  }

  return null;
}
