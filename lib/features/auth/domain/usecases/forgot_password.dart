import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';

class ForgotPasswordParams extends Equatable {
  final String email;

  const ForgotPasswordParams({required this.email});

  @override
  List<Object> get props => [email];
}

class ForgotPassword {
  final AuthRepository repository;

  ForgotPassword(this.repository);

  Future<Either<Failure, void>> call(ForgotPasswordParams params) async {
    return await repository.forgotPassword(email: params.email);
  }
}
