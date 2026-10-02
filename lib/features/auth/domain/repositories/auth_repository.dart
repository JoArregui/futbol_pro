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
    String? name,
  });

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
  });

  Future<Either<Failure, Player>> getAuthenticatedPlayer();

  Future<Either<Failure, void>> logout();

  Future<bool> refreshSession();

  String getCurrentUserId();

  String getCurrentUserName();

  String getCurrentUserRole();

  Future<String?> getAuthToken();

  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(bool v);
}
