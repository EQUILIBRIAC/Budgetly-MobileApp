import 'package:budgetly_app/core/auth/app_permissions.dart';
import 'package:budgetly_app/domain/entities/auth_session.dart';
import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(authControllerProvider).session;
});

final appPermissionsProvider = Provider<AppPermissions>((ref) {
  final session = ref.watch(authSessionProvider);
  return AppPermissions(
    session?.role ?? '',
    householdMemberId: session?.householdMemberId ?? '',
  );
});
