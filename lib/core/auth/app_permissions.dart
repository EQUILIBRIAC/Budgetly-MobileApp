/// Permisos derivados del rol en sesión (el backend no valida por rol).
class AppPermissions {
  const AppPermissions(this.role, {this.householdMemberId = ''});

  final String role;
  final String householdMemberId;

  String get _role => role.trim().toLowerCase();

  bool get isRepresentative =>
      _role == 'representative' || _role == 'admin';

  bool get isMember => _role == 'member';

  bool get isKnownRole => isRepresentative || isMember;

  bool get canCreateBill => isRepresentative;
  bool get canEditBill => isRepresentative;
  bool get canDeleteBill => isRepresentative;
  bool get canInviteMember => isRepresentative;
  bool get canAddMember => isRepresentative;
  bool get canDeleteMember => isRepresentative;
  bool get canEditHousehold => isRepresentative;
  bool get canCreateHousehold => isRepresentative;
  bool get canRegisterIncomes => isRepresentative;
  bool get canConfigureIncomeBased => isRepresentative;
  bool get canCreateContribution => isRepresentative;
  bool get canViewBillsReadOnly => isMember || isRepresentative;
  bool get canViewMembersReadOnly => isMember || isRepresentative;

  bool canMarkPaymentFor(String targetHouseholdMemberId) {
    if (targetHouseholdMemberId.isEmpty) return false;
    if (isRepresentative) return true;
    if (isMember) {
      return householdMemberId.isNotEmpty &&
          targetHouseholdMemberId == householdMemberId;
    }
    return false;
  }

  /// Plan Free: máximo 1 hogar y 3 miembros (validación UI).
  bool canCreateAnotherHousehold({
    required int ownedHouseholdCount,
    required bool isPremiumPlan,
  }) {
    if (!isRepresentative) return false;
    if (isPremiumPlan) return true;
    return ownedHouseholdCount < 1;
  }

  bool canAddAnotherMember({
    required int currentMemberCount,
    required bool isPremiumPlan,
  }) {
    if (!isRepresentative) return false;
    if (isPremiumPlan) return true;
    return currentMemberCount < 3;
  }
}
