import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pantalla cuando el JWT trae un rol no soportado por la app.
class UnknownRoleScreen extends ConsumerWidget {
  const UnknownRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final role = ref.watch(authControllerProvider).role;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 64, color: Colors.orange.shade700),
                const SizedBox(height: 16),
                Text(
                  l.t('Rol no soportado', 'Unsupported role'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l.t(
                    'Tu cuenta tiene el rol «$role», que esta versión de Budgetly '
                    'no reconoce. Contacta al administrador o usa otra cuenta.',
                    'Your account has role «$role», which this version of Budgetly '
                    'does not recognize. Contact an administrator or use another account.',
                  ),
                  style: const TextStyle(
                    color: AppColors.labelGray,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  child: Text(l.forgotPasswordBackToLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
