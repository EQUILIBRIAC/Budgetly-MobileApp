import 'package:budgetly_app/core/auth/app_permissions.dart';
import 'package:budgetly_app/core/auth/role_navigation.dart';
import 'package:budgetly_app/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPermissions', () {
    test('representative puede crear facturas y marcar pagos ajenos', () {
      const perms = AppPermissions('representative', householdMemberId: 'hm-rep');
      expect(perms.canCreateBill, isTrue);
      expect(perms.canMarkPaymentFor('hm-other'), isTrue);
    });

    test('member solo marca su propio pago', () {
      const perms = AppPermissions('member', householdMemberId: 'hm-self');
      expect(perms.canCreateBill, isFalse);
      expect(perms.canMarkPaymentFor('hm-self'), isTrue);
      expect(perms.canMarkPaymentFor('hm-other'), isFalse);
    });

    test('plan Free limita hogares y miembros', () {
      const perms = AppPermissions('representative');
      expect(
        perms.canCreateAnotherHousehold(
          ownedHouseholdCount: 0,
          isPremiumPlan: false,
        ),
        isTrue,
      );
      expect(
        perms.canCreateAnotherHousehold(
          ownedHouseholdCount: 1,
          isPremiumPlan: false,
        ),
        isFalse,
      );
      expect(
        perms.canAddAnotherMember(
          currentMemberCount: 2,
          isPremiumPlan: false,
        ),
        isTrue,
      );
      expect(
        perms.canAddAnotherMember(
          currentMemberCount: 3,
          isPremiumPlan: false,
        ),
        isFalse,
      );
    });

    test('rol desconocido no tiene permisos', () {
      const perms = AppPermissions('guest');
      expect(perms.isKnownRole, isFalse);
      expect(perms.canViewBillsReadOnly, isFalse);
    });
  });

  group('RoleNavigation', () {
    test('member sin hogar va a buscar hogar', () {
      const session = AuthSession(
        userId: '1',
        email: 'm@test.com',
        token: 't',
        householdId: '',
        role: 'member',
        plan: 'Free',
      );
      expect(RoleNavigation.homeFor(session), '/member/search-household');
    });

    test('rol unknown va a pantalla de error', () {
      const session = AuthSession(
        userId: '1',
        email: 'x@test.com',
        token: 't',
        householdId: '',
        role: 'unknown',
        plan: 'Free',
      );
      expect(RoleNavigation.homeFor(session), '/auth/unknown-role');
    });
  });
}
