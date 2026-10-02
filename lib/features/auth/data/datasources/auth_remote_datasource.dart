import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:futbol_pro/core/consts.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';
import 'package:futbol_pro/core/storage/secure_storage_service.dart';
import '../../../match_scheduling/domain/entities/player.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';

String get _kBaseUrl => '${AppConsts.effectiveBaseUrl}/auth';

abstract class AuthRemoteDataSource {
  Future<Player> login(LoginParams params);
  Future<Player> register(RegisterParams params);
  Future<Player> getAuthenticatedPlayer();
  Future<void> logout();

  /// Intenta rotar el par de tokens con el refresh guardado.
  /// Devuelve true si se obtuvo un access nuevo.
  Future<bool> refreshSession();
  String getCurrentUserId();
  String getCurrentUserName();
  String getCurrentUserRole();
  Future<String?> getAuthToken();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool v);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final SecureStorageService secureStorage;

  String _currentUserId = '';
  String _currentUserName = '';
  String _currentUserRole = 'player';
  String? _token;
  String? _refreshToken;
  bool _storageLoaded = false;

  AuthRemoteDataSourceImpl({required this.client, required this.secureStorage});

  Player _parseAuthResponse(Map<String, dynamic> body) {
    // Nuevo formato {user, token, role} o legacy plano
    final Map<String, dynamic> userJson = body['user'] is Map
        ? Map<String, dynamic>.from(body['user'] as Map)
        : body;
    if (body['role'] != null) userJson['role'] = body['role'];
    if (userJson['id'] != null) userJson['id'] = userJson['id'].toString();
    return Player.fromJson(userJson);
  }

  Future<void> _persist(
    Player player,
    String? token, [
    String? refreshToken,
  ]) async {
    _currentUserId = player.id;
    _currentUserName = player.name;
    _currentUserRole = player.role;
    _token = token ?? _token;
    _refreshToken = refreshToken ?? _refreshToken;
    await secureStorage.persistUser(
      userId: player.id,
      userName: player.name,
      userJson: jsonEncode(player.toJson()),
      token: _token,
      refreshToken: _refreshToken,
      role: player.role,
    );
  }

  // ===============================================
  // LOGIN SEGURO (sin anonimato, sin fallback offline)
  // ===============================================
  @override
  Future<Player> login(LoginParams params) async {
    final url = Uri.parse('$_kBaseUrl/login');
    try {
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': params.email,
              'password': params.password,
            }),
          )
          .timeout(AppConsts.httpTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final player = _parseAuthResponse(jsonResponse);
        final token = jsonResponse['token']?.toString();
        final refreshToken = jsonResponse['refreshToken']?.toString();
        if (player.id.isEmpty) {
          throw const ServerException(
            message: 'Respuesta inválida del servidor',
          );
        }
        await _persist(player, token, refreshToken);
        return player;
      } else if (response.statusCode == 401) {
        throw const ServerException(message: 'Credenciales inválidas');
      } else {
        String serverMsg = response.body;
        try {
          serverMsg =
              (jsonDecode(response.body) as Map)['message']?.toString() ??
              serverMsg;
        } catch (_) {}
        throw ServerException(
          message: 'Error de servidor (${response.statusCode}): $serverMsg',
        );
      }
    } on TimeoutException {
      // Sin anonimato: offline NO entra. Solo reanuda si ya había sesión válida.
      throw const ServerException(
        message:
            'Sin conexión al servidor. No se permite entrar sin validar credenciales.',
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }

  // ===============================================
  // IMPLEMENTACIÓN DE REGISTER (API REST)
  // ===============================================
  @override
  Future<Player> register(RegisterParams params) async {
    final url = Uri.parse('$_kBaseUrl/register');
    // Validación cliente rápida para evitar 500 por campos vacíos
    if (params.email.isEmpty ||
        params.password.isEmpty ||
        params.nickname.isEmpty) {
      throw const ServerException(
        message: 'Faltan campos obligatorios (email, password, nickname).',
      );
    }
    try {
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': params.email,
              'password': params.password,
              'nickname': params.nickname,
              'name': params.name,
            }),
          )
          .timeout(AppConsts.httpTimeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final player = _parseAuthResponse(jsonResponse);
        final token = jsonResponse['token']?.toString();
        final refreshToken = jsonResponse['refreshToken']?.toString();
        await _persist(player, token, refreshToken);
        return player;
      } else if (response.statusCode == 409) {
        String msg = 'El usuario ya existe.';
        try {
          msg =
              (jsonDecode(response.body) as Map)['message']?.toString() ?? msg;
        } catch (_) {}
        throw ServerException(message: msg);
      } else {
        String serverMsg = response.body;
        try {
          serverMsg =
              (jsonDecode(response.body) as Map)['message']?.toString() ??
              serverMsg;
        } catch (_) {}
        throw ServerException(
          message: 'Error de registro (${response.statusCode}): $serverMsg',
        );
      }
    } on TimeoutException {
      // Sin anonimato: no se crea usuario demo offline.
      throw const ServerException(
        message: 'Sin conexión al servidor. No se puede registrar sin validar.',
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }

  @override
  Future<Player> getAuthenticatedPlayer() async {
    if (!_storageLoaded) {
      final storedId = await secureStorage.getUserId();
      final storedName = await secureStorage.getUserName();
      final storedRole = await secureStorage.getRole();
      _token = await secureStorage.getToken();
      _refreshToken = await secureStorage.getRefreshToken();
      if (storedId != null && storedId.isNotEmpty) {
        _currentUserId = storedId;
        _currentUserName = storedName ?? '';
        _currentUserRole = storedRole ?? 'player';
      }
      _storageLoaded = true;
    }
    // Sin token = sin sesión (nunca anónima)
    if (_currentUserId.isEmpty || _token == null || _token!.isEmpty) {
      throw const UnauthenticatedException();
    }
    // JWT caducado: no aceptar caché como válida; intentar rotar una vez.
    if (_isExpired(_token!)) {
      final ok = await refreshSession();
      if (!ok) throw const UnauthenticatedException();
    }
    final cached = await secureStorage.getUserJson();
    if (cached != null) {
      try {
        final p = Player.fromJson(jsonDecode(cached));
        _currentUserId = p.id;
        _currentUserName = p.name;
        _currentUserRole = p.role;
        return p;
      } catch (_) {}
    }
    // Validar token contra /auth/me
    try {
      final url = Uri.parse('$_kBaseUrl/me');
      final response = await client
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final p = Player.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map),
        );
        await _persist(p, _token);
        return p;
      }
    } catch (_) {}
    throw const UnauthenticatedException();
  }

  /// true si el JWT expiró (decodifica `exp` sin verificar firma;
  /// la verificación real la hace el servidor).
  bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      payload += '=' * ((4 - payload.length % 4) % 4);
      final json =
          jsonDecode(String.fromCharCodes(base64Decode(payload))) as Map;
      final exp = (json['exp'] as num?)?.toInt();
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> refreshSession() async {
    _refreshToken ??= await secureStorage.getRefreshToken();
    final rt = _refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      // Ojo: esta petición pasa por AuthenticatedClient, que excluye
      // /auth/refresh del reintento para no entrar en bucle.
      final url = Uri.parse('$_kBaseUrl/refresh');
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': rt}),
          )
          .timeout(AppConsts.httpTimeout);
      if (response.statusCode == 200) {
        final body = Map<String, dynamic>.from(
          jsonDecode(response.body) as Map,
        );
        final newToken = body['token']?.toString();
        final newRefresh = body['refreshToken']?.toString();
        if (newToken == null || newToken.isEmpty) return false;
        _token = newToken;
        if (newRefresh != null && newRefresh.isNotEmpty) {
          _refreshToken = newRefresh;
        }
        await secureStorage.persistTokens(
          token: _token,
          refreshToken: _refreshToken,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    // Revocación best-effort en servidor (no bloquea el logout local).
    try {
      final url = Uri.parse('$_kBaseUrl/logout');
      final body = _refreshToken != null && _refreshToken!.isNotEmpty
          ? jsonEncode({'refreshToken': _refreshToken})
          : '{}';
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_token != null && _token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_token';
      }
      await client
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // noop: el logout local siempre se ejecuta
    }
    _currentUserId = '';
    _currentUserName = '';
    _currentUserRole = 'player';
    _token = null;
    _refreshToken = null;
    _storageLoaded = true;
    await secureStorage.clear();
  }

  @override
  String getCurrentUserId() {
    return _currentUserId;
  }

  @override
  String getCurrentUserName() {
    return _currentUserName;
  }

  @override
  String getCurrentUserRole() => _currentUserRole;

  @override
  Future<String?> getAuthToken() async {
    _token ??= await secureStorage.getToken();
    return _token;
  }

  @override
  Future<bool> isBiometricEnabled() => secureStorage.isBiometricEnabled();

  @override
  Future<void> setBiometricEnabled(bool v) =>
      secureStorage.setBiometricEnabled(v);

  @override
  Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$_kBaseUrl/forgot-password');
    try {
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(AppConsts.httpTimeout);

      if (response.statusCode != 200) {
        String serverMsg = response.body;
        try {
          serverMsg =
              (jsonDecode(response.body) as Map)['message']?.toString() ??
                  serverMsg;
        } catch (_) {}
        throw ServerException(
          message: 'Error al solicitar restablecimiento (${response.statusCode}): $serverMsg',
        );
      }
    } on TimeoutException {
      throw const ServerException(
        message: 'Sin conexión al servidor. Inténtalo más tarde.',
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }

  @override
  Future<void> resetPassword(String token, String password) async {
    final url = Uri.parse('$_kBaseUrl/reset-password');
    try {
      final response = await client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'password': password}),
          )
          .timeout(AppConsts.httpTimeout);

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        String msg = 'Token inválido o expirado.';
        try {
          msg = (jsonDecode(response.body) as Map)['message']?.toString() ?? msg;
        } catch (_) {}
        throw ServerException(message: msg);
      } else {
        String serverMsg = response.body;
        try {
          serverMsg =
              (jsonDecode(response.body) as Map)['message']?.toString() ??
                  serverMsg;
        } catch (_) {}
        throw ServerException(
          message: 'Error al restablecer contraseña (${response.statusCode}): $serverMsg',
        );
      }
    } on TimeoutException {
      throw const ServerException(
        message: 'Sin conexión al servidor. Inténtalo más tarde.',
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }
}
