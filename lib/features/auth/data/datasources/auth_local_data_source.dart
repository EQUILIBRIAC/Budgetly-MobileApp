import '../../../../core/storage/storage_service.dart';

abstract interface class SessionLocalContract {
  Future<String?> token();
  Future<Map<String, dynamic>?> cachedUserJson();
  Future<void> persist({
    required String token,
    required Map<String, dynamic> userJson,
  });

  Future<void> clearAll();
}

class AuthLocalDataSource implements SessionLocalContract {
  AuthLocalDataSource();

  @override
  Future<String?> token() => StorageService.getToken();

  @override
  Future<Map<String, dynamic>?> cachedUserJson() => StorageService.getUser();

  @override
  Future<void> persist({
    required String token,
    required Map<String, dynamic> userJson,
  }) async {
    await StorageService.saveToken(token);
    await StorageService.saveUser(userJson);
  }

  @override
  Future<void> clearAll() => StorageService.clearAll();
}
