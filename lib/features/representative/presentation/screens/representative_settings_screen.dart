import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/settings_entity.dart';
import 'package:budgetly_app/app/providers/app_ui_providers.dart';
import 'package:budgetly_app/core/storage/ui_prefs_storage.dart';
import 'package:budgetly_app/core/utils/api_value_parsers.dart';
import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:budgetly_app/features/representative/presentation/providers/representative_provider.dart';
import 'package:budgetly_app/features/representative/presentation/widgets/representative_dashboard_layout.dart';

/// Ajustes de cuenta (paridad con dashboard web): preferencias API + zona de peligro.
class RepresentativeSettingsScreen extends ConsumerStatefulWidget {
  const RepresentativeSettingsScreen({super.key});

  @override
  ConsumerState<RepresentativeSettingsScreen> createState() =>
      _RepresentativeSettingsScreenState();
}

class _RepresentativeSettingsScreenState
    extends ConsumerState<RepresentativeSettingsScreen> {
  late final HttpService _http;
  UserSettings? _settings;
  UserSettings? _lastSaved;
  bool _loading = true;
  bool _saving = false;
  String? _msg;
  String _emailDisplay = '';

  Future<void> _persistUiFromSettings(UserSettings s) async {
    final code = s.language.toLowerCase().startsWith('en') ? 'en' : 'es';
    await UiPrefsStorage.saveThemeDark(s.darkMode);
    await UiPrefsStorage.saveLocaleCode(code);
    if (!mounted) return;
    ref.read(appThemeModeProvider.notifier).state =
        s.darkMode ? ThemeMode.dark : ThemeMode.light;
    ref.read(appLocaleProvider.notifier).state = Locale(code);
  }

  Future<void> _refreshEmailSubtitle() async {
    final auth = ref.read(authControllerProvider);
    var e = normalizeApiEmail(auth.currentUser?.email ?? '');
    if (e.contains('@')) {
      if (mounted) setState(() => _emailDisplay = e);
      return;
    }
    final userMap = await StorageService.getUser();
    e = normalizeApiEmail(userMap?['email']);
    if (e.contains('@')) {
      if (mounted) setState(() => _emailDisplay = e);
      return;
    }
    final tok = await StorageService.getToken();
    if (tok != null && tok.isNotEmpty) {
      final j = decodeEmailFromJwt(tok);
      if (j != null && j.contains('@')) {
        if (mounted) setState(() => _emailDisplay = j);
        return;
      }
    }
    if (mounted) setState(() => _emailDisplay = '');
  }

  @override
  void initState() {
    super.initState();
    _http = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _reload();
      await _refreshEmailSubtitle();
    } catch (_) {
      _msg = 'No se pudieron cargar los ajustes.';
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _reload() async {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) _http.setToken(token);
    final userJson = await StorageService.getUser();
    final userId = userJson?['id']?.toString() ?? '';
    if (userId.isEmpty) throw Exception('ID de usuario inválido.');
    UserSettings loaded;
    try {
      final res = await _http.get(ApiPaths.settingsByUserQuery(userId));
      final parsed = ApiJson.objectData(res);
      loaded = parsed != null
          ? UserSettings.fromJson(parsed)
          : UserSettings(
              id: '',
              userId: userId,
              language: 'es',
              darkMode: false,
              notificationEnabled: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
    } catch (_) {
      loaded = UserSettings(
        id: '',
        userId: userId,
        language: 'es',
        darkMode: false,
        notificationEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    _settings = loaded;
    _lastSaved = loaded;
    await _persistUiFromSettings(loaded);
  }

  Future<void> _save() async {
    final s = _settings;
    if (s == null) return;
    setState(() {
      _saving = true;
      _msg = null;
    });
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) _http.setToken(token);
      final next = s.copyWith(updatedAt: DateTime.now());
      final payload = next.toApiBody();
      final Map<String, dynamic> res;
      if (next.id.isEmpty) {
        res = await _http.post(ApiPaths.settingsRoot, body: payload);
      } else {
        res = await _http.put(ApiPaths.settingsById(next.id), body: payload);
      }
      final parsed = ApiJson.objectData(res);
      final saved = parsed != null &&
              (parsed['id'] != null || parsed['userId'] != null)
          ? UserSettings.fromJson(parsed)
          : next;
      if (mounted) {
        setState(() {
          _settings = saved;
          _lastSaved = saved;
          _msg = 'Cambios guardados.';
        });
      }
      await _persistUiFromSettings(saved);
    } catch (e) {
      setState(() => _msg = ApiFailure.wrap(e).messageEs);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    if (_lastSaved != null) {
      setState(() {
        _settings = _lastSaved;
        _msg = null;
      });
      _persistUiFromSettings(_lastSaved!);
    }
  }

  bool _dirty() {
    final a = _settings;
    final b = _lastSaved;
    if (a == null || b == null) return false;
    return a.language != b.language ||
        a.darkMode != b.darkMode ||
        a.notificationEnabled != b.notificationEnabled;
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado')),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    var email = normalizeApiEmail(
      ref.read(authControllerProvider).currentUser?.email ?? '',
    );
    if (!email.contains('@')) {
      email = normalizeApiEmail(_emailDisplay);
    }
    if (!email.contains('@')) {
      final tok = await StorageService.getToken();
      if (tok != null && tok.isNotEmpty) {
        final j = decodeEmailFromJwt(tok);
        email = normalizeApiEmail(j);
      }
    }
    if (!email.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo obtener el correo para esta acción; cierra sesión y entra de nuevo.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Esta acción desactiva tu usuario y no se puede deshacer. '
              'Escribe tu correo para confirmar.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Correo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (ctrl.text.trim().toLowerCase() != email.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El correo no coincide.')),
      );
      return;
    }
    try {
      await ref.read(representativeActionsProvider).deleteAccountByEmail(email);
      await ref.read(authControllerProvider).signOut();
      if (mounted) context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiFailure.wrap(e).messageEs)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return RepresentativeDashboardLayout(
      currentRoute: AppRoutes.repSettings,
      child: _loading || _settings == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Configuración de cuenta',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Preferencias y opciones a nivel cuenta.',
                    style: TextStyle(color: AppColors.textGray, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        label: 'Usuario',
                        color: AppColors.dashGreen.withValues(alpha: 0.2),
                        textColor: AppColors.dashGreen,
                      ),
                      _Badge(
                        label: 'ID: ${auth.currentUser?.id ?? '—'}',
                        color: AppColors.dashBadgeBlue,
                        textColor: AppColors.dashBlue,
                      ),
                      _Badge(
                        label: 'Plan ${auth.currentUser?.plan ?? 'FREE'}',
                        color: AppColors.dashBadgeGray,
                        textColor: AppColors.labelGray,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.borderGray),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Preferencias',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _emailDisplay.isNotEmpty
                                ? _emailDisplay
                                : 'Sin correo en el perfil local. Cierra sesión y vuelve a entrar para sincronizarlo.',
                            style: const TextStyle(color: AppColors.textGray),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Idioma',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'es', label: Text('ES')),
                              ButtonSegment(value: 'en', label: Text('EN')),
                            ],
                            selected: {_settings!.language.startsWith('en') ? 'en' : 'es'},
                            onSelectionChanged: (s) {
                              final lang = s.first == 'en' ? 'en' : 'es';
                              setState(() {
                                _msg = null;
                                _settings = _settings!.copyWith(language: lang);
                              });
                              ref.read(appLocaleProvider.notifier).state =
                                  Locale(lang);
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Modo oscuro'),
                            subtitle: Text(_settings!.darkMode ? 'Activado' : 'Desactivado'),
                            value: _settings!.darkMode,
                            activeThumbColor: AppColors.dashGreen,
                            onChanged: (v) {
                              setState(() {
                                _msg = null;
                                _settings = _settings!.copyWith(darkMode: v);
                              });
                              ref.read(appThemeModeProvider.notifier).state =
                                  v ? ThemeMode.dark : ThemeMode.light;
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Notificaciones por correo'),
                            subtitle: Text(
                              _settings!.notificationEnabled ? 'Activadas' : 'Desactivadas',
                            ),
                            value: _settings!.notificationEnabled,
                            activeThumbColor: AppColors.dashGreen,
                            onChanged: (v) => setState(() {
                              _msg = null;
                              _settings =
                                  _settings!.copyWith(notificationEnabled: v);
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Creado: ${DateFormat('dd/MM/yyyy HH:mm').format(_settings!.createdAt)} · '
                            'Actualizado: ${DateFormat('dd/MM/yyyy HH:mm').format(_settings!.updatedAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.labelGray,
                            ),
                          ),
                          if (_msg != null) ...[
                            const SizedBox(height: 10),
                            Text(_msg!, style: const TextStyle(color: AppColors.teal)),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: _dirty() ? _reset : null,
                                child: const Text('Restablecer'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed:
                                    !_dirty() || _saving ? null : _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.dashGreen,
                                  foregroundColor: AppColors.white,
                                  disabledBackgroundColor:
                                      AppColors.borderGray,
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Guardar cambios'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dirty()
                                ? 'Pulsa «Guardar cambios» para enviar la configuración al servidor.'
                                : 'Sin cambios pendientes. Modifica idioma, tema o notificaciones para habilitar Guardar.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.labelGray,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: auth.currentUser?.id.isNotEmpty == true
                                ? () => _copy(auth.currentUser!.id)
                                : null,
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copiar mi ID'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    color: AppColors.dangerBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zona de peligro',
                            style: TextStyle(
                              color: AppColors.dangerRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Eliminar la cuenta puede desactivar miembros vinculados. '
                            'No se puede deshacer.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.dangerRed,
                              ),
                              onPressed: _confirmDeleteAccount,
                              child: const Text('Eliminar cuenta'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
