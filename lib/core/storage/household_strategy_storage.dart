import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgetly_app/core/constants/storage_keys.dart';
import 'package:budgetly_app/domain/entities/income_split_entities.dart';

/// Preferencia local de estrategia de reparto por hogar.
class HouseholdStrategyStorage {
  static String _key(String householdId) =>
      '${StorageKeys.householdDefaultStrategyPrefix}$householdId';

  static Future<EStrategy> loadDefaultStrategy(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key(householdId));
    return EStrategy.fromInt(raw);
  }

  static Future<bool> isIncomeBasedEnabled(String householdId) async {
    final strategy = await loadDefaultStrategy(householdId);
    return strategy == EStrategy.incomeBased;
  }

  static Future<void> saveDefaultStrategy(
    String householdId,
    EStrategy strategy,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(householdId), strategy.value);
  }
}
