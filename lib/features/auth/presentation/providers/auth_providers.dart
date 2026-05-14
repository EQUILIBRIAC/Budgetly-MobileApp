import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session_revoker.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/http_service.dart';
import '../../../../core/storage/jwt_token_locator.dart';
import '../../../../domain/entities/user.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final httpClientProvider = Provider<HttpService>((_) {
  return HttpService(baseUrl: EnvConfig.apiBaseUrl);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(httpClientProvider));
});

final authLocalDataSourceProvider = Provider<SessionLocalContract>((_) {
  return AuthLocalDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required HttpService httpClient,
  })  : _repository = repository,
        _httpClient = httpClient {
    _bootstrap();
  }

  final AuthRepository _repository;
  final HttpService _httpClient;

  AuthStatus _status = AuthStatus.loading;
  User? _currentUser;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String get role => _currentUser?.role.toLowerCase() ?? '';

  Future<void> _bootstrap() async {
    try {
      final user = await _repository.restorePersistedSession();
      if (user == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        final token = await JwtTokenLocator.instance.read();
        if (token != null && token.isNotEmpty) {
          _httpClient.setToken(token);
        }
        _currentUser = user;
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _repository.signIn(email: email, password: password);
    _currentUser = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _httpClient.clearToken();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final repo = ref.watch(authRepositoryProvider);
  final ctrl = AuthController(repository: repo, httpClient: httpClient);

  Future.microtask(() {
    SessionRevoker.bind(ctrl.signOut);
  });

  ref.onDispose(SessionRevoker.clear);

  return ctrl;
});
