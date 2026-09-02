import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:futbol_pro/core/consts.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';
import 'package:futbol_pro/core/storage/secure_storage_service.dart';
import '../../../match_scheduling/domain/entities/player.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
const String _kBaseUrl = '${AppConsts.baseUrl}/auth';


abstract class AuthRemoteDataSource {
  Future<Player> login(LoginParams params);
  Future<Player> register(RegisterParams params);
  Future<Player> getAuthenticatedPlayer();
  Future<void> logout();
  String getCurrentUserId();
  String getCurrentUserName();
}


class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final SecureStorageService secureStorage;

  String _currentUserId = '';
  String _currentUserName = '';
  bool _storageLoaded = false;

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.secureStorage,
  });


  // ===============================================
  // IMPLEMENTACIÓN DE LOGIN (API REST)
  // ===============================================
  @override
  Future<Player> login(LoginParams params) async {
    final url = Uri.parse('$_kBaseUrl/login');
    
    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': params.email,
          'password': params.password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final player = Player.fromJson(jsonResponse);
        _currentUserId = player.id;
        _currentUserName = player.name;
        await secureStorage.persistUser(
          userId: player.id,
          userName: player.name,
          userJson: jsonEncode(player.toJson()),
        );
        return player;
      } else if (response.statusCode == 401) {
        // 401 Unauthorized: Credenciales incorrectas
        throw const ServerException(message: 'Credenciales inválidas');
      } else {
        // Otros errores del servidor (e.g., 500 Internal Server Error)
        throw ServerException(message: 'Error de servidor: ${response.statusCode}');
      }
    } on Exception catch (e) {
      // Captura errores de conexión (e.g., si el servidor Node.js no está corriendo)
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }


  // ===============================================
  // IMPLEMENTACIÓN DE REGISTER (API REST)
  // ===============================================
  @override
  Future<Player> register(RegisterParams params) async {
    final url = Uri.parse('$_kBaseUrl/register');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': params.email,
          'password': params.password,
          'nickname': params.nickname,
          'name': params.name,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final player = Player.fromJson(jsonResponse);
        _currentUserId = player.id;
        _currentUserName = player.name;
        await secureStorage.persistUser(
          userId: player.id,
          userName: player.name,
          userJson: jsonEncode(player.toJson()),
        );
        return player;
      } else if (response.statusCode == 409) {
        // 409 Conflict: Email/Apodo ya registrado (debería manejarlo la API)
        throw const ServerException(message: 'El usuario ya existe.');
      } else {
        throw ServerException(message: 'Error de registro: ${response.statusCode}');
      }
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<Player> getAuthenticatedPlayer() async {
    if (!_storageLoaded) {
      final storedId = await secureStorage.getUserId();
      final storedName = await secureStorage.getUserName();
      if (storedId != null && storedId.isNotEmpty) {
        _currentUserId = storedId;
        _currentUserName = storedName ?? '';
      }
      _storageLoaded = true;
    }
    if (_currentUserId.isNotEmpty) {
      final cached = await secureStorage.getUserJson();
      if (cached != null) {
        try {
          return Player.fromJson(jsonDecode(cached));
        } catch (_) {}
      }
      // Fallback: intenta refrescar desde API si hay ID pero no JSON
      try {
        final url = Uri.parse('${AppConsts.baseUrl}/users/$_currentUserId/profile');
        final response = await client.get(url, headers: {'Content-Type': 'application/json'});
        if (response.statusCode == 200) {
          return Player.fromJson(jsonDecode(response.body));
        }
      } catch (_) {}
      // Si no se pudo refrescar, devuelve player mínimo con datos cacheados
      return Player(
        id: _currentUserId,
        name: _currentUserName,
        nickname: _currentUserName,
        profileImageUrl: '',
      );
    }
    throw const UnauthenticatedException();
  }

  @override
  Future<void> logout() async {
    _currentUserId = '';
    _currentUserName = '';
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
}