import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _kUserId = 'auth_user_id';
  static const _kUserName = 'auth_user_name';
  static const _kUserJson = 'auth_user_json';
  static const _kToken = 'auth_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kRole = 'auth_role';
  static const _kBiometricEnabled = 'auth_biometric_enabled';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> persistUser({
    required String userId,
    required String userName,
    String? userJson,
    String? token,
    String? refreshToken,
    String? role,
  }) async {
    await _storage.write(key: _kUserId, value: userId);
    await _storage.write(key: _kUserName, value: userName);
    if (userJson != null) {
      await _storage.write(key: _kUserJson, value: userJson);
    }
    if (token != null) {
      await _storage.write(key: _kToken, value: token);
    }
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    }
    if (role != null) {
      await _storage.write(key: _kRole, value: role);
    }
  }

  Future<void> persistTokens({String? token, String? refreshToken}) async {
    if (token != null) {
      await _storage.write(key: _kToken, value: token);
    }
    if (refreshToken != null) {
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    }
  }

  Future<String?> getUserId() => _storage.read(key: _kUserId);
  Future<String?> getUserName() => _storage.read(key: _kUserName);
  Future<String?> getUserJson() => _storage.read(key: _kUserJson);
  Future<String?> getToken() => _storage.read(key: _kToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> getRole() => _storage.read(key: _kRole);

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _kBiometricEnabled) == 'true';
  Future<void> setBiometricEnabled(bool v) async =>
      await _storage.write(key: _kBiometricEnabled, value: v ? 'true' : 'false');

  Future<void> clear() async {
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kUserName);
    await _storage.delete(key: _kUserJson);
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kRole);
    // Nota: se conserva _kBiometricEnabled para ofrecer huella al volver.
  }

  Future<void> clearAll() async {
    await clear();
    await _storage.delete(key: _kBiometricEnabled);
  }
}
