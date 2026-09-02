import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _kUserId = 'auth_user_id';
  static const _kUserName = 'auth_user_name';
  static const _kUserJson = 'auth_user_json';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> persistUser({
    required String userId,
    required String userName,
    String? userJson,
  }) async {
    await _storage.write(key: _kUserId, value: userId);
    await _storage.write(key: _kUserName, value: userName);
    if (userJson != null) {
      await _storage.write(key: _kUserJson, value: userJson);
    }
  }

  Future<String?> getUserId() => _storage.read(key: _kUserId);
  Future<String?> getUserName() => _storage.read(key: _kUserName);
  Future<String?> getUserJson() => _storage.read(key: _kUserJson);

  Future<void> clear() async {
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kUserName);
    await _storage.delete(key: _kUserJson);
  }
}
