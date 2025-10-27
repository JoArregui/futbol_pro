import 'package:dartz/dartz.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../match_scheduling/domain/entities/player.dart';
// Importamos los parámetros necesarios para crear las clases de la capa Data Source
import '../../domain/usecases/login_user.dart'; 
import '../../domain/usecases/register_user.dart'; 
import '../datasources/auth_remote_dataSource.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';

/// Implementación del AuthRepository que maneja la lógica de negocio
/// y el mapeo de excepciones de la capa de datos a fallos de la capa de dominio.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  /// Implementación del método 'login' de la interfaz AuthRepository.
  /// Llama al Data Source con la clase LoginParams.
  @override
  Future<Either<Failure, Player>> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Convertimos los parámetros de dominio a la clase de parámetros de Data Source
      final params = LoginParams(email: email, password: password);
      
      // 2. Llamamos al Data Source (el nombre del método en DS es 'login', no 'loginUser')
      final player = await remoteDataSource.login(params);
      return Right(player);
    } on ServerException catch (e) {
      // ✅ CORREGIDO: Se pasa el mensaje como argumento POSICIONAL.
      return Left(ServerFailure(e.message)); 
    } on Exception {
      // Manejo de cualquier otra excepción inesperada
      return Left(ServerFailure('Error desconocido al intentar iniciar sesión.'));
    }
  }

  /// Implementación del método 'register' de la interfaz AuthRepository.
  @override
  Future<Either<Failure, Player>> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      // 1. Convertimos los parámetros de dominio a la clase de parámetros de Data Source
      final params = RegisterParams(
        email: email, 
        password: password, 
        nickname: nickname,
      );
      
      // 2. Llamamos al Data Source 
      final player = await remoteDataSource.register(params);
      return Right(player);
    } on ServerException catch (e) {
      // ✅ CORREGIDO: Se pasa el mensaje como argumento POSICIONAL.
      return Left(ServerFailure(e.message));
    } on Exception {
      return Left(ServerFailure('Error desconocido al intentar registrar el usuario.'));
    }
  }

  /// Implementación del método 'getAuthenticatedPlayer'
  @override
  Future<Either<Failure, Player>> getAuthenticatedPlayer() async {
    try {
      final player = await remoteDataSource.getAuthenticatedPlayer();
      return Right(player);
    } on UnauthenticatedException {
      // ✅ CORREGIDO: Se pasa el mensaje como argumento POSICIONAL. Mapea a CacheFailure.
      return Left(CacheFailure('No hay sesión activa.'));
    } on Exception {
      // ✅ CORREGIDO: Se pasa el mensaje como argumento POSICIONAL.
      return Left(ServerFailure('Error al verificar sesión.'));
    }
  }

  /// Implementación del método 'logout'
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on Exception {
      // ✅ CORREGIDO: Se pasa el mensaje como argumento POSICIONAL.
      return Left(ServerFailure('Error al cerrar sesión.'));
    }
  }
}
