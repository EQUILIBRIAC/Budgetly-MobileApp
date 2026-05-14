import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/storage/jwt_token_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  JwtTokenLocator.useSecureDefaultStore();

  await initializeDateFormatting(EnvConfig.localeDefault);

  runApp(const ProviderScope(child: BudgetlyApp()));
}

