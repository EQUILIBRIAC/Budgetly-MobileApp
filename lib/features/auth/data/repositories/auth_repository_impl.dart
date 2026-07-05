import 'package:budgetly_app/core/auth/session_resolver.dart';
import 'package:budgetly_app/core/network/api_failure.dart';
import 'package:budgetly_app/domain/entities/auth_session.dart';
import 'package:budgetly_app/domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SessionLocalContract localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final SessionLocalContract _local;

  AuthSession? _lastSession;

  AuthSession? get lastSession => _lastSession;

  @override
  Future<User?> restorePersistedSession() async {
    final token = await _local.token();
    final userJson = await _local.cachedUserJson();
    if (token == null || token.isEmpty || userJson == null) {
      return null;
    }
    final stored = Map<String, dynamic>.from(userJson);
    stored['token'] = token;
    _lastSession = AuthSession.fromStoredJson(stored);
    return _sessionToUser(_lastSession!);
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _remote.signIn(email: email, password: password);
    final tokenOrNull = _remote.lastToken;
    if (tokenOrNull == null) {
      throw ApiFailure.generic('No se recibió token.');
    }

    var householdMemberId = '';
    final role = result.user.role.toLowerCase();
    if (role == 'member' && result.user.householdId.isNotEmpty) {
      householdMemberId = await SessionResolver.resolveHouseholdMemberId(
            http: _remote.http,
            userId: result.user.id,
            householdId: result.user.householdId,
          ) ??
          '';
    }

    _lastSession = AuthSession(
      userId: result.user.id,
      email: result.user.email,
      token: tokenOrNull,
      householdId: result.user.householdId,
      role: result.user.role,
      plan: result.user.plan,
      householdMemberId: householdMemberId,
      isNewUser: result.user.isNewUser,
    );

    await _local.persist(
      token: tokenOrNull,
      userJson: _lastSession!.toJson(),
    );

    return _sessionToUser(_lastSession!);
  }

  @override
  Future<void> signOut() async {
    _lastSession = null;
    await _local.clearAll();
  }

  Future<void> updateStoredSession(AuthSession session) async {
    _lastSession = session;
    await _local.persist(token: session.token, userJson: session.toJson());
  }

  User _sessionToUser(AuthSession session) {
    return User(
      id: session.userId,
      email: session.email,
      role: session.role,
      householdId: session.householdId,
      isNewUser: session.isNewUser,
      plan: session.plan,
    );
  }
}
