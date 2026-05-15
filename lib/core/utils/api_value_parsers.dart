import 'dart:convert';

/// Parsing defensivo de valores que ASP.NET puede enviar como string, objeto anidado,
/// tipo serializado incorrectamente (`ValueObjects.EmailAddress`), etc.

String normalizeApiEmail(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) {
    final s = raw.trim();
    if (s.contains('@')) return s;
    if (s.contains('.Domain.') ||
        s.contains('ValueObjects.') ||
        s.contains('IAM.')) {
      return '';
    }
    return '';
  }
  if (raw is Map) {
    for (final key in const [
      'value',
      'Value',
      'address',
      'Address',
      'email',
      'Email',
      'normalizedEmail',
    ]) {
      if (!raw.containsKey(key)) continue;
      final inner = normalizeApiEmail(raw[key]);
      if (inner.isNotEmpty) return inner;
    }
  }
  return '';
}

bool parseApiBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}

/// `es`, `es-ES`, `en`, `english`, etc.
String normalizeLanguageCode(dynamic raw, [String fallback = 'es']) {
  if (raw == null) return fallback;
  final s = raw.toString().trim().toLowerCase();
  if (s.startsWith('es')) return 'es';
  if (s.startsWith('en')) return 'en';
  return fallback;
}

/// Email dentro del JWT (útil cuando el JSON de usuario local falló).
String? decodeEmailFromJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final segment = parts[1];
    final normalized =
        segment.replaceAll('-', '+').replaceAll('_', '/');
    final padded =
        normalized + '=' * ((4 - normalized.length % 4) % 4);
    final map = jsonDecode(utf8.decode(base64Decode(padded)))
        as Map<String, dynamic>;
    const keys = [
      'email',
      'Email',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
      'preferred_username',
    ];
    for (final k in keys) {
      if (!map.containsKey(k)) continue;
      final parsed = normalizeApiEmail(map[k]);
      if (parsed.contains('@')) return parsed;
    }
    for (final v in map.values) {
      final parsed = normalizeApiEmail(v);
      if (parsed.contains('@')) return parsed;
    }
  } catch (_) {}
  return null;
}
