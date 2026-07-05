import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:budgetly_app/app/providers/app_ui_providers.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/storage/ui_prefs_storage.dart';
import 'package:budgetly_app/domain/entities/settings_entity.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/app/l10n/app_localizations.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_page_styles.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_dashboard_layout.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';

class MemberSettingsScreen extends ConsumerStatefulWidget {
  const MemberSettingsScreen({super.key});

  @override
  ConsumerState<MemberSettingsScreen> createState() =>
      _MemberSettingsScreenState();
}

class _MemberSettingsScreenState extends ConsumerState<MemberSettingsScreen> {
  late HttpService _httpService;

  UserSettings? _settings;
  UserSettings? _lastSaved;
  bool _loading = true;
  bool _saving = false;
  String _successMessage = '';
  String _errorMessage = '';

  String _normalizedLanguage(String raw) =>
      raw.toLowerCase().startsWith('en') ? 'en' : 'es';

  String _languageLabel(AppLocalizations l, String code) =>
      code == 'en' ? l.english : l.spanish;

  @override
  void initState() {
    super.initState();
    _httpService = HttpService(baseUrl: EnvConfig.apiBaseUrl);
    _loadSettings();
  }

  Future<void> _persistUiFromSettings(UserSettings s) async {
    final code = s.language.toLowerCase().startsWith('en') ? 'en' : 'es';
    await UiPrefsStorage.saveThemeDark(s.darkMode);
    await UiPrefsStorage.saveLocaleCode(code);
    if (!mounted) return;
    ref.read(appThemeModeProvider.notifier).state =
        s.darkMode ? ThemeMode.dark : ThemeMode.light;
    ref.read(appLocaleProvider.notifier).state = Locale(code);
  }

  void _applyThemeImmediately(bool dark) {
    UiPrefsStorage.saveThemeDark(dark);
    ref.read(appThemeModeProvider.notifier).state =
        dark ? ThemeMode.dark : ThemeMode.light;
  }

  void _applyLanguageImmediately(String language) {
    final code = language.toLowerCase().startsWith('en') ? 'en' : 'es';
    UiPrefsStorage.saveLocaleCode(code);
    ref.read(appLocaleProvider.notifier).state = Locale(code);
  }

  Future<UserSettings> _mergeWithLocalUiPrefs(UserSettings loaded) async {
    final localTheme = await UiPrefsStorage.loadThemeMode();
    final localLocale = await UiPrefsStorage.loadLocale();
    return loaded.copyWith(
      darkMode: localTheme == ThemeMode.dark,
      language: _normalizedLanguage(
        localLocale?.languageCode ?? loaded.language,
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      final token = await StorageService.getToken();
      if (token != null) {
        _httpService.setToken(token);
      }

      final userJson = await StorageService.getUser();
      if (userJson == null) {
        throw Exception('Usuario no encontrado');
      }

      final userId = userJson['id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('ID de usuario inválido');
      }

      UserSettings loaded;
      try {
        final response =
            await _httpService.get(ApiPaths.settingsByUserQuery(userId));
        final parsed = ApiJson.objectData(response);
        if (parsed != null) {
          loaded = UserSettings.fromJson(parsed);
        } else {
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

      loaded = loaded.copyWith(language: _normalizedLanguage(loaded.language));
      loaded = await _mergeWithLocalUiPrefs(loaded);

      setState(() {
        _settings = loaded;
        _lastSaved = loaded;
      });
      await _persistUiFromSettings(loaded);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar ajustes: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    try {
      setState(() {
        _saving = true;
        _successMessage = '';
        _errorMessage = '';
      });

      final updatedSettings = _settings!.copyWith(
        updatedAt: DateTime.now(),
      );

      final payload = updatedSettings.toApiBody();

      final Map<String, dynamic> response;
      if (updatedSettings.id.isEmpty) {
        response = await _httpService.post(
          ApiPaths.settingsRoot,
          body: payload,
        );
      } else {
        response = await _httpService.put(
          ApiPaths.settingsById(updatedSettings.id),
          body: payload,
        );
      }

      final parsed = ApiJson.objectData(response);
      final savedSettings = parsed != null &&
              (parsed['id'] != null || parsed['userId'] != null)
          ? UserSettings.fromJson(parsed)
          : updatedSettings.copyWith(updatedAt: DateTime.now());

      setState(() {
        _settings = savedSettings;
        _lastSaved = savedSettings;
        _successMessage = context.l10n.settingsSaved;
      });
      await _persistUiFromSettings(savedSettings);

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar ajustes: $e';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  void _resetSettings() {
    if (_lastSaved != null) {
      setState(() {
        _settings = _lastSaved;
        _successMessage = '';
        _errorMessage = '';
      });
      _persistUiFromSettings(_lastSaved!);
    }
  }

  bool _isDirty() {
    if (_settings == null || _lastSaved == null) return false;
    return _settings.toString() != _lastSaved.toString();
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  Widget _buildContent() {
    final l = context.l10n;
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l.loadingSettings),
          ],
        ),
      );
    }

    if (_settings == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage.isNotEmpty
                ? _errorMessage
                : l.settingsLoadError),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              child: Text(l.retry),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Welcome Card
            Container(
              decoration: MemberPageStyles.cardDecoration(context),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsTitle,
                    style: MemberPageStyles.sectionTitle(context).copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.settingsSubtitle,
                    style: MemberPageStyles.bodyMuted(context),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(l.user, Icons.person),
                      _buildTag(
                        'ID: ${_settings!.userId}',
                        Icons.info,
                        severity: 'info',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Content - Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;
                
                if (isMobile) {
                  // Stack vertically on mobile
                  return Column(
                    children: [
                      // Preferences Card
                      _buildPreferencesCard(),
                      
                      // Summary Card
                      const SizedBox(height: 24),
                      _buildSummaryCard(),
                    ],
                  );
                } else {
                  // Stack horizontally on desktop
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column - Form
                      Expanded(
                        flex: 2,
                        child: _buildPreferencesCard(),
                      ),

                      const SizedBox(width: 24),

                      // Right Column - Summary
                      Expanded(
                        child: _buildSummaryCard(),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    final l = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      decoration: MemberPageStyles.cardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.preferences, style: MemberPageStyles.sectionTitle(context)),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.language, style: MemberPageStyles.label(context)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'es', label: Text(l.spanish)),
                  ButtonSegment(value: 'en', label: Text(l.english)),
                ],
                selected: {
                  _normalizedLanguage(_settings!.language),
                },
                onSelectionChanged: (selection) {
                  final lang = selection.first;
                  setState(() {
                    _settings = _settings!.copyWith(language: lang);
                  });
                  _applyLanguageImmediately(lang);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dark Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.darkMode, style: MemberPageStyles.label(context)),
                  const SizedBox(height: 4),
                  Text(
                    _settings!.darkMode ? l.onLabel : l.offLabel,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
              Switch(
                value: _settings!.darkMode,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings!.copyWith(darkMode: value);
                  });
                  _applyThemeImmediately(value);
                },
                activeThumbColor: AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notifications Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.emailNotifications,
                    style: MemberPageStyles.label(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _settings!.notificationEnabled ? l.enabled : l.disabled,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
              Switch(
                value: _settings!.notificationEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      notificationEnabled: value,
                    );
                  });
                },
                activeThumbColor: AppColors.teal,
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          const SizedBox(height: 24),

          // Timestamps
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.createdAt,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(_settings!.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.lastUpdated,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(_settings!.updatedAt),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isDirty() ? _resetSettings : null,
                child: Text(l.reset),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isDirty() && !_saving ? _saveSettings : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l.save),
              ),
            ],
          ),

          // Messages
          if (_successMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final l = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: MemberPageStyles.cardDecoration(context),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.summary, style: MemberPageStyles.sectionTitle(context)),
          const SizedBox(height: 16),
          _buildSummaryItem(
            l.language,
            _languageLabel(l, _normalizedLanguage(_settings!.language)),
            muted: muted,
            valueColor: onSurface,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            l.darkMode,
            _settings!.darkMode ? l.onLabel : l.offLabel,
            muted: muted,
            valueColor: onSurface,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            l.emailNotifications,
            _settings!.notificationEnabled ? l.enabled : l.disabled,
            muted: muted,
            valueColor: onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    required Color muted,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, {String severity = 'default'}) {
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade700;
    Color iconColor = Colors.grey.shade700;

    if (severity == 'info') {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      iconColor = Colors.blue.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MemberDashboardLayout(
      currentRoute: 'member-settings',
      child: _buildContent(),
    );
  }
}

