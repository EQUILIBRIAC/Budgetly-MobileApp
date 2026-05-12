import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/member_contributions_screen.dart';
import '../screens/member_dashboard_screen.dart';
import '../screens/member_household_status_screen.dart';
import '../screens/member_search_household_screen.dart';
import '../screens/member_settings_screen.dart';
import '../screens/representative_screens.dart';
import '../screens/signup_screen.dart';
import 'app_routes.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberDashboard,
        builder: (context, state) => const MemberDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberContributions,
        builder: (context, state) => const MemberContributionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberHouseholdStatus,
        builder: (context, state) => const MemberHouseholdStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberSearchHousehold,
        builder: (context, state) => const MemberSearchHouseholdScreen(),
      ),
      GoRoute(
        path: AppRoutes.memberSettings,
        builder: (context, state) => const MemberSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.repDashboard,
        builder: (context, state) => const RepresentativeDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.repHouseholds,
        builder: (context, state) => const RepresentativeHouseholdsScreen(),
      ),
      GoRoute(
        path: AppRoutes.repMembers,
        builder: (context, state) => const RepresentativeMembersScreen(),
      ),
      GoRoute(
        path: AppRoutes.repBills,
        builder: (context, state) => const RepresentativeBillsScreen(),
      ),
      GoRoute(
        path: AppRoutes.repContributions,
        builder: (context, state) => const RepresentativeContributionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.repSettings,
        builder: (context, state) => const RepresentativeSettingsScreen(),
      ),
    ],
    redirect: (context, state) {
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
    },
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
