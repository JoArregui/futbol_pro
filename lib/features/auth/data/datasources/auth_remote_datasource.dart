import 'package:http/http.dart' as http;
import 'dart:convert'; // Necesario para jsonEncode y jsonDecode

import '../../../match_scheduling/domain/entities/player.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';
import 'dart:async';


// ===============================================
// URL BASE DE TU API REST (Node.js/Express)
// ===============================================
// Usamos 10.0.2.2 como alias de localhost para el emulador de Android.
const String _kBaseUrl = 'http://10.0.2.2:3000/api/v1/auth'; 


abstract class AuthRemoteDataSource {
  Future<Player> login(LoginParams params);
  Future<Player> register(RegisterParams params);
  Future<Player> getAuthenticatedPlayer();
  Future<void> logout();
  String getCurrentUserId();
  String getCurrentUserName();
}


class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  
  // ❌ Eliminada la dependencia 'final FirebaseFirestore firestore;'
  final http.Client client;

  // Variables para mantener el estado del usuario (usadas en getCurrentUserId/Name)
  String _currentUserId = '';
  String _currentUserName = '';

  // Constructor simplificado
  AuthRemoteDataSourceImpl({required this.client});


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
        // La API devuelve un JSON con los datos del Player
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final player = Player.fromJson(jsonResponse); 

        // Actualizamos el estado local
        _currentUserId = player.id;
        _currentUserName = player.name; 

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

      if (response.statusCode == 201) { // Código 201 Created
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final player = Player.fromJson(jsonResponse); 
        
        // Actualizamos el estado local después del registro exitoso
        _currentUserId = player.id;
        _currentUserName = player.name;

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

  // ===============================================
  // MÉTODOS DE ESTADO (MOCK)
  // ===============================================
  
  @override
  Future<Player> getAuthenticatedPlayer() async {
    // Implementación MOCK temporal: Si tenemos un ID, simulamos devolver el Player
    if (_currentUserId.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      // NOTA: En una app real, aquí harías una llamada GET a /api/v1/user/$_currentUserId
      throw const UnauthenticatedException(); // Mantenemos el throw para forzar el re-login en el inicio.
    }
    throw const UnauthenticatedException();
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // NOTA: En una app real, harías una llamada al backend para invalidar el token/sesión.
    _currentUserId = '';
    _currentUserName = ''; 
    return;
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