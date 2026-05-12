import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/settings_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';
import 'member_dashboard_layout.dart';

class MemberSettingsScreen extends StatefulWidget {
  const MemberSettingsScreen({super.key});

  @override
  State<MemberSettingsScreen> createState() => _MemberSettingsScreenState();
}

class _MemberSettingsScreenState extends State<MemberSettingsScreen> {
  late HttpService _httpService;

  UserSettings? _settings;
  UserSettings? _lastSaved;
  bool _loading = true;
  bool _saving = false;
  String _successMessage = '';
  String _errorMessage = '';

  final List<String> _languages = ['en', 'es', 'pt', 'fr'];
  final Map<String, String> _languageNames = {
    'en': 'English',
    'es': 'Español',
    'pt': 'Português',
    'fr': 'Français',
  };

  @override
  void initState() {
    super.initState();
    _httpService = HttpService(baseUrl: ApiConfig.baseUrl);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      // Get token from storage and set it on the service
      final token = await StorageService.getToken();
      if (token != null) {
        _httpService.setToken(token);
      }

      // Get user from storage
      final userJson = await StorageService.getUser();
      if (userJson == null) {
        throw Exception('No user found');
      }

      final userId = userJson['id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Try to load settings from API
      try {
        final response = await _httpService.get(
          '/api/v1/settings/$userId',
        );

      if (response.isNotEmpty) {
        final settings = UserSettings.fromJson(response);
          setState(() {
            _settings = settings;
            _lastSaved = settings;
          });
        } else {
          // Create default settings
          final defaultSettings = UserSettings(
            id: '',
            userId: userId,
            language: 'en',
            darkMode: false,
            notificationEnabled: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          setState(() {
            _settings = defaultSettings;
            _lastSaved = defaultSettings;
          });
        }
      } catch (e) {
        // Settings don't exist yet, create defaults
        final defaultSettings = UserSettings(
          id: '',
          userId: userId,
          language: 'en',
          darkMode: false,
          notificationEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        setState(() {
          _settings = defaultSettings;
          _lastSaved = defaultSettings;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading settings: $e';
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

      late final Map<String, dynamic> response;

      if (updatedSettings.id.isEmpty) {
        // Create new settings
        response = await _httpService.post(
          '/api/v1/settings/create',
          body: updatedSettings.toJson(),
        );
      } else {
        // Update existing settings
        response = await _httpService.post(
          '/api/v1/settings/${updatedSettings.id}',
          body: updatedSettings.toJson(),
        );
      }

      final savedSettings = UserSettings.fromJson(response);
      setState(() {
        _settings = savedSettings;
        _lastSaved = savedSettings;
        _successMessage = 'Settings saved successfully!';
      });

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _successMessage = '';
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving settings: $e';
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
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading settings...'),
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
                : 'Failed to load settings'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSettings,
              child: const Text('Retry'),
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
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0f172a),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your preferences and account settings',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTag('User', Icons.person),
                          _buildTag(
                            'ID: ${_settings!.userId}',
                            Icons.info,
                            severity: 'info',
                          ),
                        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0f172a),
            ),
          ),
          const SizedBox(height: 20),

          // Language Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0f172a),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _settings!.language,
                  underline: Container(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  items: _languages
                      .map((lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(
                          _languageNames[lang] ?? lang,
                        ),
                      ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _settings = _settings!.copyWith(
                          language: value,
                        );
                      });
                    }
                  },
                ),
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
                  const Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _settings!.darkMode ? 'On' : 'Off',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Switch(
                value: _settings!.darkMode,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      darkMode: value,
                    );
                  });
                },
                activeColor: const Color(0xFF275954),
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
                  const Text(
                    'Email Notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _settings!.notificationEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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
                activeColor: const Color(0xFF275954),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
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
                          'Created At',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(_settings!.createdAt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0f172a),
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
                          'Last Updated',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(_settings!.updatedAt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0f172a),
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
                child: const Text('Reset'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isDirty() && !_saving ? _saveSettings : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF275954),
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
                    : const Text('Save'),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0f172a),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'Language',
            _languageNames[_settings!.language] ?? _settings!.language,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Dark Mode',
            _settings!.darkMode ? 'On' : 'Off',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Notifications',
            _settings!.notificationEnabled ? 'Enabled' : 'Disabled',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0f172a),
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
      child: _buildContent(),
      currentRoute: 'member-settings',
    );
  }
}
