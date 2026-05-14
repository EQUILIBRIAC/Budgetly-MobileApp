import '../../../../domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<User?> restorePersistedSession();

  Future<User> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
