import 'dart:convert';

/// Parsing defensivo de valores que ASP.NET puede enviar como string, objeto anidado,
/// tipo serializado incorrectamente (`ValueObjects.EmailAddress`), etc.

/// Nombre de persona desde JSON del API (`name`, `personName`, value objects).
String normalizeApiPersonName(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.contains('PersonName') ||
        s.contains('ValueObjects.') ||
        s.contains('.Domain.')) {
      return '';
    }
    return s;
  }
  if (raw is Map) {
    for (final key in const [
      'value',
      'Value',
      'name',
      'Name',
      'fullName',
      'FullName',
    ]) {
      if (!raw.containsKey(key)) continue;
      final inner = normalizeApiPersonName(raw[key]);
      if (inner.isNotEmpty) return inner;
    }
  }
  return '';
}

/// Lee nombre de persona desde mapas del API (`personName`, `name`, objetos anidados).
String? extractPersonNameFromMap(Map<String, dynamic> json) {
  for (final key in const [
    'personName',
    'name',
    'PersonName',
    'fullName',
    'displayName',
    'memberName',
  ]) {
    final parsed = normalizeApiPersonName(json[key]);
    if (parsed.isNotEmpty) return parsed;
  }
  final user = json['user'];
  if (user is Map<String, dynamic>) {
    return extractPersonNameFromMap(user);
  }
  return null;
}

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

/// Estado de aporte miembro: API puede enviar `0`/`1`, `true`/`false`, `"Pending"`, `"Done"`.
int parseMemberContributionStatus(dynamic raw, [int fallback = 0]) {
  if (raw == null) return fallback;
  if (raw is bool) return raw ? 1 : 0;
  if (raw is int) return raw;
  final s = raw.toString().trim().toLowerCase();
  if (s == '1' ||
      s == 'true' ||
      s == 'done' ||
      s == 'paid' ||
      s == 'pagado' ||
      s == 'completado' ||
      s == 'cumplido') {
    return 1;
  }
  if (s == '0' ||
      s == 'false' ||
      s == 'pending' ||
      s == 'pendiente') {
    return 0;
  }
  return int.tryParse(s) ?? fallback;
}

/// Fecha opcional: ISO-8601 o `MM/dd/yyyy` (formato habitual del API Budgetly).
DateTime? parseApiDateTimeOptional(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty || s.startsWith('01/01/0001')) return null;

  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;

  final parts = s.split('/');
  if (parts.length == 3) {
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (a != null && b != null && y != null) {
      // MM/dd/yyyy cuando el primer segmento es mes (<=12) o dd/MM si >12.
      if (a <= 12) return DateTime(y, a, b);
      return DateTime(y, b, a);
    }
  }
  return null;
}

DateTime parseApiDateTime(dynamic raw, [DateTime? fallback]) {
  return parseApiDateTimeOptional(raw) ?? fallback ?? DateTime.now();
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
