import 'package:dartz/dartz.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../match_scheduling/domain/entities/player.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../datasources/auth_remote_dataSource.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

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
      return const Left(
          ServerFailure('Error desconocido al intentar iniciar sesión.'));
    }
  }

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
      return const Left(
          ServerFailure('Error desconocido al intentar registrar el usuario.'));
    }
  }

  @override
  Future<Either<Failure, Player>> getAuthenticatedPlayer() async {
    try {
      final player = await remoteDataSource.getAuthenticatedPlayer();
      return Right(player);
    } on UnauthenticatedException {
      return const Left(CacheFailure('No hay sesión activa.'));
    } on Exception {
      return const Left(ServerFailure('Error al verificar sesión.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on Exception {
      return const Left(ServerFailure('Error al cerrar sesión.'));
    }
  }

  @override
  String getCurrentUserId() {
    return remoteDataSource.getCurrentUserId();
  }
}
