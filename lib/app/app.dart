import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_ui_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/storage/ui_prefs_storage.dart';

class BudgetlyApp extends ConsumerStatefulWidget {
  const BudgetlyApp({super.key});

  @override
  ConsumerState<BudgetlyApp> createState() => _BudgetlyAppState();
}

class _BudgetlyAppState extends ConsumerState<BudgetlyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateStoredUi());
  }

  Future<void> _hydrateStoredUi() async {
    final theme = await UiPrefsStorage.loadThemeMode();
    final locale = await UiPrefsStorage.loadLocale();
    if (!mounted) return;
    ref.read(appThemeModeProvider.notifier).state = theme;
    if (locale != null) {
      ref.read(appLocaleProvider.notifier).state = locale;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'Budgetly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
