import 'dart:async';

/// Sesión JWT inválida en peticiones ya autenticadas: limpiar estado y navegar por go_router guards.
abstract final class SessionRevoker {
  static Future<void> Function()? _handler;

  static void bind(Future<void> Function()? handler) {
    _handler = handler;
  }

  static Future<void> revokeAsync() async {
    final h = _handler;
    if (h != null) await h();
  }

  static void clear() {
    _handler = null;
  }
}
