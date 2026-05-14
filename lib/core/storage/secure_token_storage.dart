import 'storage_service.dart';

class SecureTokenStorage {
  Future<void> saveToken(String token) async {
    await StorageService.saveToken(token);
  }

  Future<String?> getToken() async {
    return StorageService.getToken();
  }

  Future<void> clearToken() async {
    await StorageService.clearToken();
  }
}
