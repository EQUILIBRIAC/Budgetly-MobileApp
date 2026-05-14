import 'package:flutter/foundation.dart';

/// Log ligero para depuración (reemplazar por logger de producción si aplica).
void logHttpDebug(String scope, Object? message) {
  if (!kDebugMode) return;
  debugPrint('[HTTP][$scope] $message');
}
