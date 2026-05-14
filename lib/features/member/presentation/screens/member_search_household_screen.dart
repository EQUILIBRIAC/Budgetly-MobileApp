import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budgetly_app/app/router/app_routes.dart';
import 'package:budgetly_app/core/config/api_paths.dart';
import 'package:budgetly_app/core/config/env_config.dart';
import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/domain/entities/household_entities.dart';
import 'package:budgetly_app/features/member/presentation/widgets/member_dashboard_layout.dart';
import 'package:budgetly_app/app/theme/app_colors.dart';

class MemberSearchHouseholdScreen extends StatefulWidget {
  const MemberSearchHouseholdScreen({super.key});

  @override
  State<MemberSearchHouseholdScreen> createState() =>
      _MemberSearchHouseholdScreenState();
}

class _MemberSearchHouseholdScreenState
    extends State<MemberSearchHouseholdScreen> {
  late final TextEditingController _codeController;
  Household? _foundHousehold;
  String _message = '';
  String _messageSeverity = 'info'; // info, warn, error, success
  bool _isSearching = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    setState(() {
      _message = '';
      _foundHousehold = null;
    });

    final q = _codeController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _message = 'Ingresa un ID de hogar.';
        _messageSeverity = 'warn';
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final httpService = HttpService(baseUrl: EnvConfig.apiBaseUrl);
      final token = await StorageService.getToken();
      if (token != null) {
        httpService.setToken(token);
      }
      final response = await httpService.get(ApiPaths.houseHold(q));

      final raw = ApiJson.objectData(response);
      if (raw == null) {
        setState(() {
          _message = 'No se encontró un hogar con ese ID.';
          _messageSeverity = 'warn';
        });
      } else {
        final household = Household.fromJson(raw);
        setState(() {
          _foundHousehold = household;
          _message = '';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al buscar el hogar: ${e.toString().replaceAll('Exception: ', '')}';
        _messageSeverity = 'error';
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _onJoin() async {
    if (_foundHousehold == null) return;

    final user = await StorageService.getUser();
    if (user == null) {
      setState(() {
        _message = 'Inicia sesión para unirte a un hogar.';
        _messageSeverity = 'warn';
      });
      return;
    }

    final userId = _toString(user['id']);
    if (userId == null || userId.isEmpty) {
      setState(() {
        _message = 'Usuario no válido.';
        _messageSeverity = 'error';
      });
      return;
    }

    final currentHouseholdId = _toString(user['householdId']);
    if (currentHouseholdId == _foundHousehold!.id) {
      setState(() {
        _message = 'Ya perteneces a este hogar.';
        _messageSeverity = 'info';
      });
      return;
    }

    setState(() => _isJoining = true);

    try {
      final httpService = HttpService(baseUrl: EnvConfig.apiBaseUrl);
      final token = await StorageService.getToken();
      if (token != null) {
        httpService.setToken(token);
      }

      final uid = int.tryParse(userId);
      if (uid == null) {
        setState(() {
          _message = 'El ID de usuario debe ser numérico para la API.';
          _messageSeverity = 'error';
        });
        return;
      }

      await httpService.post(
        ApiPaths.householdMemberRoot,
        body: {
          'householdId': _foundHousehold!.id,
          'userId': uid,
          'isRepresentative': false,
          'income': 0,
        },
      );

      // Update user in storage
      user['householdId'] = _foundHousehold!.id;
      await StorageService.saveUser(user);

      setState(() {
        _message = 'Te uniste al hogar correctamente.';
        _messageSeverity = 'success';
      });

      // Navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go(AppRoutes.memberDashboard);
        }
      });
    } catch (e) {
      setState(() {
        _message =
            'No fue posible unirte al hogar: ${e.toString().replaceAll('Exception: ', '')}';
        _messageSeverity = 'error';
      });
    } finally {
      setState(() => _isJoining = false);
    }
  }

  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    return value.toString();
  }

  Color _getMessageColor() {
    switch (_messageSeverity) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warn':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemberDashboardLayout(
      currentRoute: 'member-search-household',
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 480),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      const Text(
                        'Unirse a un hogar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Ingresa el ID proporcionado por tu representante para unirte a tu hogar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGray,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Input + Search Button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                hintText: 'Ej: HH1728345678901',
                                hintStyle:
                                    const TextStyle(color: AppColors.placeholder),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderGray,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderGray,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.teal,
                                    width: 2,
                                  ),
                                ),
                              ),
                              enabled: !_isSearching,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSearching ? null : _onSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                disabledBackgroundColor:
                                    AppColors.placeholder,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: _isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Message
                      if (_message.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _getMessageColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  _getMessageColor().withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getMessageColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Household found info
                      if (_foundHousehold != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
color: AppColors.mint.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppColors.teal.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hogar encontrado:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _foundHousehold!.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _foundHousehold!.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.labelGray,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Join Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _foundHousehold == null || _isJoining
                                  ? null
                                  : _onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            disabledBackgroundColor: AppColors.placeholder,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isJoining
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Unirme al hogar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Note
                      Text(
                        'Recuerda que este proceso es opcional. También puedes esperar a que tu representante te agregue manualmente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.labelGray.withValues(alpha: 0.95),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

