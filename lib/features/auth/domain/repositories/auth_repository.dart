import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/player.dart';

abstract class AuthRepository {
  Future<Either<Failure, Player>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, Player>> register({
    required String email,
    required String password,
    required String nickname,
  });

  Future<Either<Failure, Player>> getAuthenticatedPlayer();

  Future<Either<Failure, void>> logout();

  String getCurrentUserId();
}
