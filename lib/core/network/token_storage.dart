import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A secure storage wrapper for JWT tokens.
class TokenStorage {
  TokenStorage._internal();
  static final TokenStorage instance = TokenStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Saves both access and refresh tokens.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Saves a new access token.
  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  /// Retrieves the stored access token.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Retrieves the stored refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Deletes both tokens from secure storage.
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
