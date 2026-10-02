import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

class ResetPasswordParams extends Equatable {
  final String token;
  final String password;

  const ResetPasswordParams({required this.token, required this.password});

  @override
  List<Object> get props => [token, password];
}

class ResetPassword {
  final AuthRepository repository;

  ResetPassword(this.repository);

  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(token: params.token, password: params.password);
  }
}