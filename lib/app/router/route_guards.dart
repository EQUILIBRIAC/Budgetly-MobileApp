import 'package:go_router/go_router.dart';

import '../../core/auth/role_navigation.dart';
import '../../domain/entities/auth_session.dart';
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

  final session = auth.session;
  if (session == null) {
    return AppRoutes.login;
  }

  if (!session.isKnownRole) {
    return location == AppRoutes.unknownRole ? null : AppRoutes.unknownRole;
  }

  if (isPublic || location == AppRoutes.splash) {
    return RoleNavigation.homeFor(session);
  }

  if (session.isMember) {
    if (session.householdId.trim().isEmpty) {
      if (location == AppRoutes.memberSearchHousehold) return null;
      return AppRoutes.memberSearchHousehold;
    }
    if (location.startsWith('/rep/')) {
      return AppRoutes.memberDashboard;
    }
    return null;
  }

  if (session.isRepresentative) {
    if (location.startsWith('/member/')) {
      return AppRoutes.repDashboard;
    }
    return null;
  }

  return AppRoutes.unknownRole;
}

String homeRouteForSession(AuthSession session) =>
    RoleNavigation.homeFor(session);
