import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_page_styles.dart';

/// Pantalla guía cuando el miembro aún no pertenece a un hogar.
class MemberNoHouseholdView extends StatelessWidget {
  const MemberNoHouseholdView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 500,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_outlined, size: 56, color: scheme.outline),
              const SizedBox(height: 16),
              Text(
                l.noHouseholdTitle,
                style: MemberPageStyles.sectionTitle(context).copyWith(
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.noHouseholdBody,
                style: MemberPageStyles.bodyMuted(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.memberSearchHousehold),
                icon: const Icon(Icons.search),
                label: Text(l.searchHousehold),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onRetry,
                  child: Text(l.retry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
