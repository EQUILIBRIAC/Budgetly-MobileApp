abstract interface class JwtTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}
