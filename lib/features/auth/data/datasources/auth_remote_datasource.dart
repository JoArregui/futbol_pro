import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../match_scheduling/domain/entities/player.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';

import 'package:futbol_pro/core/errors/exceptions.dart';
import 'dart:async';

abstract class AuthRemoteDataSource {
  Future<Player> login(LoginParams params);

  Future<Player> register(RegisterParams params);

  Future<Player> getAuthenticatedPlayer();

  Future<void> logout();

  String getCurrentUserId();
  
  String getCurrentUserName();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  
  // 🟢 CORRECCIÓN: Definición de las variables miembro 'firestore' y 'client'
  final FirebaseFirestore firestore;
  final http.Client client;

  String _currentUserId = 'user-001';
  String _currentUserName = 'Juan Pro Mock';

  // Constructor actualizado para recibir las dependencias de GetIt
  AuthRemoteDataSourceImpl({required this.firestore, required this.client});

  /// Simula el inicio de sesión. Credenciales válidas: 'test@pro.com' / '123456'
  @override
  Future<Player> login(LoginParams params) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (params.email == 'test@pro.com' && params.password == '123456') {
      _currentUserId = 'user-001';
      _currentUserName = 'Juan Pro Mock'; // Almacenamos el nombre aquí
      return const Player(
        id: 'user-001',
        name: 'Juan Pro Mock',
        rating: 4.5,
        nickname: 'JP45',
        profileImageUrl: 'https://placehold.co/100x100/A0C4FF/000?text=JP',
      );
    } else {
      throw const ServerException(message: 'Credenciales inválidas');
    }
  }

  @override
  Future<Player> register(RegisterParams params) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final newId = 'user-${DateTime.now().microsecondsSinceEpoch}';
    final newName = params.name ?? 'Usuario Nuevo';
    _currentUserId = newId;
    _currentUserName = newName; // Almacenamos el nuevo nombre

    return Player(
      id: newId,
      name: newName,
      rating: 3.0,
      nickname: params.nickname,
      profileImageUrl: 'https://placehold.co/100x100/3A86FF/000?text=New',
    );
  }

  @override
  Future<Player> getAuthenticatedPlayer() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Si estás usando esta implementación de mock, querrás devolver 
    // el usuario mockeado si _currentUserId no está vacío, 
    // pero por ahora mantenemos el throw para simular que no está activo
    throw const UnauthenticatedException();
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserId = '';
    _currentUserName = ''; // Limpiamos el nombre
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