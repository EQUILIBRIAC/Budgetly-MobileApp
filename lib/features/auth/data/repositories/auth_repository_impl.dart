import 'package:budgetly_app/core/network/api_failure.dart';
import '../../../../domain/entities/user.dart';
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

  @override
  Future<User?> restorePersistedSession() async {
    final token = await _local.token();
    final userJson = await _local.cachedUserJson();
    if (token == null || token.isEmpty || userJson == null) {
      return null;
    }
    return User(
      id: userJson['id']?.toString() ?? '',
      email: userJson['email']?.toString() ?? '',
      role: userJson['role']?.toString().toLowerCase() ?? 'member',
      householdId: userJson['householdId']?.toString() ?? '',
      isNewUser: userJson['isNewUser'] == true,
      plan: userJson['plan']?.toString() ?? 'FREE',
    );
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

    await _local.persist(token: tokenOrNull, userJson: result.user.toJson());

    return result.user;
  }

  @override
  Future<void> signOut() => _local.clearAll();
}
