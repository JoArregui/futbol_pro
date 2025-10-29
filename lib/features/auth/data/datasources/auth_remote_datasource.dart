import '../../../match_scheduling/domain/entities/player.dart'; // Asegúrate de que esta ruta sea correcta
import '../../domain/usecases/login_user.dart'; // Para LoginParams
import '../../domain/usecases/register_user.dart'; // Para RegisterParams
// Importamos las excepciones necesarias
import 'package:futbol_pro/core/errors/exceptions.dart';
import 'dart:async'; // Necesario para Future.delayed

/// Interfaz para la Fuente de Datos Remota de Autenticación
abstract class AuthRemoteDataSource {
  /// Llama al endpoint de login y devuelve el Player
  Future<Player> login(LoginParams params); 

  /// Llama al endpoint de registro y devuelve el Player
  Future<Player> register(RegisterParams params); 

  /// Obtiene el Player si hay un token válido guardado
  Future<Player> getAuthenticatedPlayer();

  /// Llama al endpoint de logout y limpia el token
  Future<void> logout();

  /// 🟢 FIRMA AÑADIDA: Obtiene de forma síncrona el ID del usuario actual.
  String getCurrentUserId();
}

/// Implementación Mock de la Fuente de Datos Remota de Autenticación
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // Simula el estado de autenticación.
  String _currentUserId = 'user-001'; 

  AuthRemoteDataSourceImpl();

  /// Simula el inicio de sesión. Credenciales válidas: 'test@pro.com' / '123456'
  @override
  Future<Player> login(LoginParams params) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (params.email == 'test@pro.com' && params.password == '123456') {
      _currentUserId = 'user-001'; // Actualiza el ID al hacer login
      return const Player(
        id: 'user-001',
        name: 'Juan Pro Mock',
        rating: 4.5,
        nickname: 'JP45',
        profileImageUrl: 'https://placehold.co/100x100/A0C4FF/000?text=JP',
      );
    } else {
      throw ServerException(message: 'Credenciales inválidas');
    }
  }

  /// Simula el registro de usuario
  @override
  Future<Player> register(RegisterParams params) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    
    final newId = 'user-${DateTime.now().microsecondsSinceEpoch}';
    _currentUserId = newId; // Asume que el registro inicia sesión

    return Player(
      id: newId,
      name: params.name ?? 'Usuario Nuevo',
      rating: 3.0, // Asume un rating inicial por defecto
      nickname: params.nickname,
      profileImageUrl: 'https://placehold.co/100x100/3A86FF/000?text=New',
    );
  }

  /// Simula la verificación de una sesión guardada.
  @override
  Future<Player> getAuthenticatedPlayer() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    throw const UnauthenticatedException(); 
  }

  /// Simula el cierre de sesión.
  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserId = ''; // Limpia el ID al hacer logout
    return;
  }

  /// 🟢 IMPLEMENTACIÓN: Devuelve el ID de usuario simulado.
  @override
  String getCurrentUserId() {
    return _currentUserId;
  }
}
