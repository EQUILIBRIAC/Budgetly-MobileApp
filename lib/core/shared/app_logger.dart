import 'package:flutter/foundation.dart';

void appLog(Object? message, {String scope = 'App'}) {
  if (!kDebugMode) return;
  debugPrint('[$scope] $message');
}
