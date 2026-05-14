import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/member/presentation/screens/member_contributions_screen.dart';
import '../../features/member/presentation/screens/member_dashboard_screen.dart';
import '../../features/member/presentation/screens/member_household_status_screen.dart';
import '../../features/member/presentation/screens/member_search_household_screen.dart';
import '../../features/member/presentation/screens/member_settings_screen.dart';
import '../../features/representative/presentation/screens/representative_screens.dart';
import 'app_routes.dart';
import 'route_guards.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
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
    redirect: (context, state) =>
        resolveAuthRedirect(auth: auth, state: state),
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
