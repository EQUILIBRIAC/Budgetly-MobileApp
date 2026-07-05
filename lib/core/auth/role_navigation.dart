import '../../app/router/app_routes.dart';
import '../../domain/entities/auth_session.dart';

/// Rutas iniciales según rol y estado de onboarding.
abstract final class RoleNavigation {
  static String homeFor(AuthSession session) {
    if (!session.isKnownRole) return AppRoutes.unknownRole;
    if (session.isMember) {
      if (session.householdId.trim().isEmpty) {
        return AppRoutes.memberSearchHousehold;
      }
      return AppRoutes.memberDashboard;
    }
    return AppRoutes.repDashboard;
  }
}
