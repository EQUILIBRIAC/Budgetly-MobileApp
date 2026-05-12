import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController() {
    _bootstrap();
  }

  AuthStatus _status = AuthStatus.loading;
  User? _currentUser;
  String? _token;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String get role => _currentUser?.role.toLowerCase() ?? '';

  Future<void> _bootstrap() async {
    try {
      final token = await StorageService.getToken();
      final userJson = await StorageService.getUser();

      if (token == null || userJson == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _token = token;
      _currentUser = User(
        id: userJson['id']?.toString() ?? '',
        email: userJson['email']?.toString() ?? '',
        role: userJson['role']?.toString().toLowerCase() ?? 'member',
        householdId: userJson['householdId']?.toString() ?? '',
        isNewUser: userJson['isNewUser'] == true,
        plan: userJson['plan']?.toString() ?? 'FREE',
      );
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final http = HttpService(baseUrl: ApiConfig.baseUrl);
    final authService = AuthService(httpService: http);
    final user = await authService.signIn(email: email, password: password);
    final token = authService.lastToken;
    if (token == null) {
      throw Exception('No se recibió token.');
    }

    await StorageService.saveToken(token);
    await StorageService.saveUser(user.toJson());

    _token = token;
    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await StorageService.clearAll();
    _token = null;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
