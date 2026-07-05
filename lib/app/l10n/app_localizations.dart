import 'package:flutter/material.dart';

import '../router/app_routes.dart';

/// Traducciones ES / EN de la app.
abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get localeCode;

  /// Traducción inline ES / EN para cadenas aún no promovidas a getter.
  String t(String es, String en) => localeCode == 'en' ? en : es;

  // Común
  String get appName;
  String get retry;
  String get save;
  String get reset;
  String get cancel;
  String get confirm;
  String get loading;
  String get onLabel;
  String get offLabel;
  String get enabled;
  String get disabled;
  String get menu;
  String get summary;
  String get user;
  String get paid;
  String get pending;
  String get amount;
  String get status;
  String get expense;
  String get dueDate;
  String get all;
  String get allFeminine;

  // Auth
  String get loginTitle;
  String get loginEmptyCredentials;
  String get loginSignIn;
  String get loginForgotPassword;
  String get forgotPasswordTitle;
  String get forgotPasswordNotAvailableBody;
  String get forgotPasswordBackToLogin;

  // Roles
  String get memberRole;
  String get representativeRole;

  // Nav miembro
  String get home;
  String get bills;
  String get myContributions;
  String get settings;
  String get logout;
  String get logoutConfirmTitle;
  String get logoutConfirmBody;
  String get logoutAction;

  // Nav representante
  String get dashboard;
  String get households;
  String get members;
  String get contributions;
  String get memberIncomes;
  String get incomeSplitSettings;

  // Ajustes
  String get settingsTitle;
  String get settingsSubtitle;
  String get preferences;
  String get language;
  String get spanish;
  String get english;
  String get darkMode;
  String get emailNotifications;
  String get createdAt;
  String get lastUpdated;
  String get settingsSaved;
  String get settingsLoadError;
  String get settingsSaveError;
  String get loadingSettings;

  // Miembro — inicio
  String get filters;
  String get onlyOverdue;
  String get onlyPending;
  String get totalAssigned;
  String get next7Days;
  String get overdueContributions;
  String get overdueContributionsHint;
  String get contributionsSummary;
  String get noDataForFilters;
  String get currentMonth;
  String get last3Months;
  String get customRange;

  // Miembro — gastos / aportes
  String get householdBills;
  String get householdBillsReadOnly;
  String get noBillsYet;
  String get myContributionsTitle;
  String get monthlyIncome;
  String get incomePrivacyHint;
  String get yourContributions;
  String get noContributionsYet;
  String get markPayment;
  String get noHouseholdTitle;
  String get noHouseholdBody;
  String get searchHousehold;

  // Drawer secciones
  String get menuSection;
  String get generalSection;
  String get toolsSection;
  String get profile;
  String get action;
  String get registeredContributions;
  String get incomeUpdatedSuccess;
  String markAsPaidConfirm(String amount, String expense);
  String get paymentRegisteredSuccess;
  String get paymentsNotSupportedYet;
  String get saveChanges;
  String get settingsDirtyHint;
  String get settingsCleanHint;
  String get noEmailInProfile;
  String get copyMyId;
  String get copied;
  String get accountSettingsTitle;
  String get accountSettingsSubtitle;
  String get incomeSplitSettingsSubtitle;
  String get dangerZone;
  String get dangerZoneBody;
  String get deleteAccount;
  String get deleteAccountTitle;
  String get deleteAccountBody;
  String get emailLabel;
  String get emailMismatch;
  String get deleteAction;
  String get emailRequiredForAction;
  String planLabel(String plan);
  String get alertsComingSoon;
  String get currencyHint;
}

class AppLocalizationsEs extends AppLocalizations {
  @override
  String get localeCode => 'es';

  @override
  String get appName => 'Budgetly';
  @override
  String get retry => 'Reintentar';
  @override
  String get save => 'Guardar';
  @override
  String get reset => 'Restablecer';
  @override
  String get cancel => 'Cancelar';
  @override
  String get confirm => 'Confirmar';
  @override
  String get loading => 'Cargando…';
  @override
  String get onLabel => 'Activado';
  @override
  String get offLabel => 'Desactivado';
  @override
  String get enabled => 'Activadas';
  @override
  String get disabled => 'Desactivadas';
  @override
  String get menu => 'Menú';
  @override
  String get summary => 'Resumen';
  @override
  String get user => 'Usuario';
  @override
  String get paid => 'Pagado';
  @override
  String get pending => 'Pendiente';
  @override
  String get amount => 'Monto';
  @override
  String get status => 'Estado';
  @override
  String get expense => 'Gasto';
  @override
  String get dueDate => 'Vence';
  @override
  String get all => 'Todos';
  @override
  String get allFeminine => 'Todas';

  @override
  String get loginTitle => '¡Bienvenido de nuevo!';
  @override
  String get loginEmptyCredentials =>
      'Completa tu correo y contraseña.';
  @override
  String get loginSignIn => 'Iniciar sesión';
  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';
  @override
  String get forgotPasswordTitle => 'Recuperar contraseña';
  @override
  String get forgotPasswordNotAvailableBody =>
      'El API no expone recuperación de contraseña. Contacta a soporte.';
  @override
  String get forgotPasswordBackToLogin => 'Volver al inicio de sesión';

  @override
  String get memberRole => 'Miembro';
  @override
  String get representativeRole => 'Representante';

  @override
  String get home => 'Inicio';
  @override
  String get bills => 'Gastos';
  @override
  String get myContributions => 'Mis aportes';
  @override
  String get settings => 'Ajustes';
  @override
  String get logout => 'Salir';
  @override
  String get logoutConfirmTitle => 'Cerrar sesión';
  @override
  String get logoutConfirmBody =>
      '¿Estás seguro de que deseas cerrar sesión?';
  @override
  String get logoutAction => 'Cerrar sesión';

  @override
  String get dashboard => 'Panel';
  @override
  String get households => 'Hogares';
  @override
  String get members => 'Miembros';
  @override
  String get contributions => 'Aportes';
  @override
  String get memberIncomes => 'Ingresos de miembros';
  @override
  String get incomeSplitSettings => 'Reparto por ingreso';

  @override
  String get settingsTitle => 'Configuración';
  @override
  String get settingsSubtitle => 'Administra tus preferencias y cuenta';
  @override
  String get preferences => 'Preferencias';
  @override
  String get language => 'Idioma';
  @override
  String get spanish => 'Español';
  @override
  String get english => 'English';
  @override
  String get darkMode => 'Modo oscuro';
  @override
  String get emailNotifications => 'Notificaciones por correo';
  @override
  String get createdAt => 'Creado';
  @override
  String get lastUpdated => 'Última actualización';
  @override
  String get settingsSaved => 'Ajustes guardados.';
  @override
  String get settingsLoadError => 'Error al cargar ajustes';
  @override
  String get settingsSaveError => 'Error al guardar ajustes';
  @override
  String get loadingSettings => 'Cargando ajustes…';

  @override
  String get filters => 'Filtros';
  @override
  String get onlyOverdue => 'Solo vencidos';
  @override
  String get onlyPending => 'Solo pendientes';
  @override
  String get totalAssigned => 'Total asignado';
  @override
  String get next7Days => 'Próximos 7 días';
  @override
  String get overdueContributions => 'Aportes vencidos';
  @override
  String get overdueContributionsHint =>
      'Contribuciones con fecha vencida';
  @override
  String get contributionsSummary => 'Resumen de tus contribuciones';
  @override
  String get noDataForFilters =>
      'No hay datos para los filtros seleccionados.';
  @override
  String get currentMonth => 'Mes actual';
  @override
  String get last3Months => 'Últimos 3 meses';
  @override
  String get customRange => 'Personalizado';

  @override
  String get householdBills => 'Gastos del hogar';
  @override
  String get householdBillsReadOnly =>
      'Solo lectura. El representante registra y reparte los gastos.';
  @override
  String get noBillsYet =>
      'Aún no hay gastos registrados en tu hogar.';
  @override
  String get myContributionsTitle => 'Mis aportes';
  @override
  String get monthlyIncome => 'Ingreso mensual';
  @override
  String get incomePrivacyHint =>
      'Este dato solo es visible para ti y nos permite estimar metas personalizadas.';
  @override
  String get yourContributions => 'Tus aportes';
  @override
  String get noContributionsYet =>
      'No tienes contribuciones asignadas aún.';
  @override
  String get markPayment => 'Marcar pago';
  @override
  String get noHouseholdTitle => 'Aún no perteneces a un hogar';
  @override
  String get noHouseholdBody =>
      'Busca tu hogar con el ID que te compartió tu representante para ver aportes y estado.';
  @override
  String get searchHousehold => 'Buscar hogar';

  @override
  String get menuSection => 'MENÚ';
  @override
  String get generalSection => 'GENERAL';
  @override
  String get toolsSection => 'HERRAMIENTAS';
  @override
  String get profile => 'Perfil';
  @override
  String get action => 'Acción';
  @override
  String get registeredContributions => 'Contribuciones registradas';
  @override
  String get incomeUpdatedSuccess => 'Ingreso actualizado correctamente.';
  @override
  String markAsPaidConfirm(String amount, String expense) =>
      '¿Confirmas el pago de $amount para «$expense»?';
  @override
  String get paymentRegisteredSuccess => 'Pago registrado correctamente.';
  @override
  String get paymentsNotSupportedYet =>
      'El servidor no soporta marcar pagos todavía.';
  @override
  String get saveChanges => 'Guardar cambios';
  @override
  String get settingsDirtyHint =>
      'Pulsa «Guardar cambios» para enviar la configuración al servidor.';
  @override
  String get settingsCleanHint =>
      'Sin cambios pendientes. Modifica idioma, tema o notificaciones para habilitar Guardar.';
  @override
  String get noEmailInProfile =>
      'Sin correo en el perfil local. Cierra sesión y vuelve a entrar para sincronizarlo.';
  @override
  String get copyMyId => 'Copiar mi ID';
  @override
  String get copied => 'Copiado';
  @override
  String get accountSettingsTitle => 'Configuración de cuenta';
  @override
  String get accountSettingsSubtitle =>
      'Preferencias y opciones a nivel cuenta.';
  @override
  String get incomeSplitSettingsSubtitle =>
      'Configura el reparto proporcional y recalcula aportes.';
  @override
  String get dangerZone => 'Zona de peligro';
  @override
  String get dangerZoneBody =>
      'Eliminar la cuenta puede desactivar miembros vinculados. No se puede deshacer.';
  @override
  String get deleteAccount => 'Eliminar cuenta';
  @override
  String get deleteAccountTitle => 'Eliminar cuenta';
  @override
  String get deleteAccountBody =>
      'Esta acción desactiva tu usuario y no se puede deshacer. Escribe tu correo para confirmar.';
  @override
  String get emailLabel => 'Correo';
  @override
  String get emailMismatch => 'El correo no coincide.';
  @override
  String get deleteAction => 'Eliminar';
  @override
  String get emailRequiredForAction =>
      'No se pudo obtener el correo para esta acción; cierra sesión y entra de nuevo.';
  @override
  String planLabel(String plan) => 'Plan $plan';
  @override
  String get alertsComingSoon => 'Alertas (próximamente)';
  @override
  String get currencyHint => 'S/ 0.00';
}

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get localeCode => 'en';

  @override
  String get appName => 'Budgetly';
  @override
  String get retry => 'Retry';
  @override
  String get save => 'Save';
  @override
  String get reset => 'Reset';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get loading => 'Loading…';
  @override
  String get onLabel => 'On';
  @override
  String get offLabel => 'Off';
  @override
  String get enabled => 'Enabled';
  @override
  String get disabled => 'Disabled';
  @override
  String get menu => 'Menu';
  @override
  String get summary => 'Summary';
  @override
  String get user => 'User';
  @override
  String get paid => 'Paid';
  @override
  String get pending => 'Pending';
  @override
  String get amount => 'Amount';
  @override
  String get status => 'Status';
  @override
  String get expense => 'Expense';
  @override
  String get dueDate => 'Due';
  @override
  String get all => 'All';
  @override
  String get allFeminine => 'All';

  @override
  String get loginTitle => 'Welcome back!';
  @override
  String get loginEmptyCredentials =>
      'Please enter your email and password.';
  @override
  String get loginSignIn => 'Sign in';
  @override
  String get loginForgotPassword => 'Forgot password?';
  @override
  String get forgotPasswordTitle => 'Reset password';
  @override
  String get forgotPasswordNotAvailableBody =>
      'Password recovery is not available via the API. Contact support.';
  @override
  String get forgotPasswordBackToLogin => 'Back to sign in';

  @override
  String get memberRole => 'Member';
  @override
  String get representativeRole => 'Representative';

  @override
  String get home => 'Home';
  @override
  String get bills => 'Bills';
  @override
  String get myContributions => 'My contributions';
  @override
  String get settings => 'Settings';
  @override
  String get logout => 'Log out';
  @override
  String get logoutConfirmTitle => 'Sign out';
  @override
  String get logoutConfirmBody => 'Are you sure you want to sign out?';
  @override
  String get logoutAction => 'Sign out';

  @override
  String get dashboard => 'Dashboard';
  @override
  String get households => 'Households';
  @override
  String get members => 'Members';
  @override
  String get contributions => 'Contributions';
  @override
  String get memberIncomes => 'Member incomes';
  @override
  String get incomeSplitSettings => 'Income-based split';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsSubtitle => 'Manage your preferences and account';
  @override
  String get preferences => 'Preferences';
  @override
  String get language => 'Language';
  @override
  String get spanish => 'Español';
  @override
  String get english => 'English';
  @override
  String get darkMode => 'Dark mode';
  @override
  String get emailNotifications => 'Email notifications';
  @override
  String get createdAt => 'Created';
  @override
  String get lastUpdated => 'Last updated';
  @override
  String get settingsSaved => 'Settings saved.';
  @override
  String get settingsLoadError => 'Failed to load settings';
  @override
  String get settingsSaveError => 'Failed to save settings';
  @override
  String get loadingSettings => 'Loading settings…';

  @override
  String get filters => 'Filters';
  @override
  String get onlyOverdue => 'Overdue only';
  @override
  String get onlyPending => 'Pending only';
  @override
  String get totalAssigned => 'Total assigned';
  @override
  String get next7Days => 'Next 7 days';
  @override
  String get overdueContributions => 'Overdue contributions';
  @override
  String get overdueContributionsHint => 'Contributions past due date';
  @override
  String get contributionsSummary => 'Your contributions summary';
  @override
  String get noDataForFilters => 'No data matches the selected filters.';
  @override
  String get currentMonth => 'Current month';
  @override
  String get last3Months => 'Last 3 months';
  @override
  String get customRange => 'Custom';

  @override
  String get householdBills => 'Household bills';
  @override
  String get householdBillsReadOnly =>
      'Read only. Your representative records and splits expenses.';
  @override
  String get noBillsYet => 'No bills registered in your household yet.';
  @override
  String get myContributionsTitle => 'My contributions';
  @override
  String get monthlyIncome => 'Monthly income';
  @override
  String get incomePrivacyHint =>
      'Only you can see this. It helps us suggest personalized goals.';
  @override
  String get yourContributions => 'Your contributions';
  @override
  String get noContributionsYet => 'You have no assigned contributions yet.';
  @override
  String get markPayment => 'Mark paid';
  @override
  String get noHouseholdTitle => 'You are not in a household yet';
  @override
  String get noHouseholdBody =>
      'Search for your household using the ID from your representative.';
  @override
  String get searchHousehold => 'Find household';

  @override
  String get menuSection => 'MENU';
  @override
  String get generalSection => 'GENERAL';
  @override
  String get toolsSection => 'TOOLS';
  @override
  String get profile => 'Profile';
  @override
  String get action => 'Action';
  @override
  String get registeredContributions => 'Registered contributions';
  @override
  String get incomeUpdatedSuccess => 'Income updated successfully.';
  @override
  String markAsPaidConfirm(String amount, String expense) =>
      'Confirm payment of $amount for «$expense»?';
  @override
  String get paymentRegisteredSuccess => 'Payment recorded successfully.';
  @override
  String get paymentsNotSupportedYet =>
      'The server does not support marking payments yet.';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get settingsDirtyHint =>
      'Tap «Save changes» to send your settings to the server.';
  @override
  String get settingsCleanHint =>
      'No pending changes. Change language, theme or notifications to enable Save.';
  @override
  String get noEmailInProfile =>
      'No email in local profile. Sign out and sign in again to sync it.';
  @override
  String get copyMyId => 'Copy my ID';
  @override
  String get copied => 'Copied';
  @override
  String get accountSettingsTitle => 'Account settings';
  @override
  String get accountSettingsSubtitle => 'Account-level preferences and options.';
  @override
  String get incomeSplitSettingsSubtitle =>
      'Configure proportional split and recalculate contributions.';
  @override
  String get dangerZone => 'Danger zone';
  @override
  String get dangerZoneBody =>
      'Deleting your account may deactivate linked members. This cannot be undone.';
  @override
  String get deleteAccount => 'Delete account';
  @override
  String get deleteAccountTitle => 'Delete account';
  @override
  String get deleteAccountBody =>
      'This deactivates your user and cannot be undone. Type your email to confirm.';
  @override
  String get emailLabel => 'Email';
  @override
  String get emailMismatch => 'Email does not match.';
  @override
  String get deleteAction => 'Delete';
  @override
  String get emailRequiredForAction =>
      'Could not get email for this action; sign out and sign in again.';
  @override
  String planLabel(String plan) => 'Plan $plan';
  @override
  String get alertsComingSoon => 'Alerts (coming soon)';
  @override
  String get currencyHint => 'S/ 0.00';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'es' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'en') {
      return AppLocalizationsEn();
    }
    return AppLocalizationsEs();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Título de pantalla representante según ruta.
String representativeScreenTitle(BuildContext context, String route) {
  final l = AppLocalizations.of(context);
  switch (route) {
    case AppRoutes.repDashboard:
      return l.dashboard;
    case AppRoutes.repHouseholds:
      return l.households;
    case AppRoutes.repMembers:
      return l.members;
    case AppRoutes.repMemberIncomes:
      return l.memberIncomes;
    case AppRoutes.repBills:
      return l.bills;
    case AppRoutes.repContributions:
      return l.contributions;
    case AppRoutes.repSettings:
      return l.settings;
    case AppRoutes.repHouseholdIncomeSettings:
      return l.incomeSplitSettings;
    default:
      return l.appName;
  }
}

/// Título de pantalla miembro según clave de ruta interna.
String memberScreenTitle(BuildContext context, String routeKey) {
  final l = AppLocalizations.of(context);
  switch (routeKey) {
    case 'member-dashboard':
      return l.home;
    case 'member-bills':
      return l.bills;
    case 'member-contributions':
      return l.myContributions;
    case 'member-settings':
      return l.settings;
    default:
      return l.appName;
  }
}
