import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(l.forgotPasswordTitle),
        backgroundColor: AppColors.cream,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.forgotPasswordNotAvailableBody,
              style: const TextStyle(
                color: AppColors.labelGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text(l.forgotPasswordBackToLogin),
            ),
          ],
        ),
      ),
    );
  }
}
