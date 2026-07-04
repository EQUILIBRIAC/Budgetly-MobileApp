class StorageKeys {
  static const authToken = 'auth_token';
  static const userData = 'user_data';
  /// UI local (preferencias cargadas también desde `/settings`).
  static const uiDarkMode = 'budgetly_ui_dark_mode';
  static const uiLocale = 'budgetly_ui_locale';
  static const memberDisplayNamesByUserId = 'budgetly_member_display_names_by_user_id';
  static const memberDisplayNamesByEmail = 'budgetly_member_display_names_by_email';
  /// EStrategy por hogar: 1 = Even, 2 = IncomeBased.
  static const householdDefaultStrategyPrefix = 'budgetly_household_strategy_';
}
