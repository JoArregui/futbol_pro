import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/player.dart';

abstract class AuthRepository {
  /// Intenta iniciar sesión con email y contraseña.
  Future<Either<Failure, Player>> login({
    required String email,
    required String password,
  });

  /// Intenta registrar un nuevo usuario y devuelve la Entidad Player creada.
  Future<Either<Failure, Player>> register({
    required String email,
    required String password,
    required String nickname,
  });

  /// Obtiene el estado de autenticación actual (útil al iniciar la app).
  Future<Either<Failure, Player>> getAuthenticatedPlayer();

  /// Cierra la sesión del usuario.
  Future<Either<Failure, void>> logout();
}
