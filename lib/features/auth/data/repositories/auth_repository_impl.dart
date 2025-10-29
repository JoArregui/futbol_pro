import 'package:dartz/dartz.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../match_scheduling/domain/entities/player.dart';
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
  @override
  Future<Either<Failure, Player>> login({
    required String email,
    required String password,
  }) async {
    try {
      final params = LoginParams(email: email, password: password);
      final player = await remoteDataSource.login(params);
      return Right(player);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message)); 
    } on Exception {
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
      final params = RegisterParams(
        email: email, 
        password: password, 
        nickname: nickname,
      );
      final player = await remoteDataSource.register(params);
      return Right(player);
    } on ServerException catch (e) {
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
      return Left(CacheFailure('No hay sesión activa.'));
    } on Exception {
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
      return Left(ServerFailure('Error al cerrar sesión.'));
    }
  }

  /// 🟢 SOLUCIÓN: Implementación concreta del método síncrono.
  @override
  String getCurrentUserId() {
    // Delegamos la lógica síncrona al Data Source
    return remoteDataSource.getCurrentUserId();
  }
}
