import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/player.dart';
import '../repositories/auth_repository.dart';
import 'package:futbol_pro/core/usecases/usecase.dart';

class LoginUser implements UseCase<Player, LoginParams> {
  final AuthRepository repository;

  LoginUser(this.repository);

  @override
  Future<Either<Failure, Player>> call(LoginParams params) async {
    // Aquí puedes incluir validaciones de email o contraseña si no se hicieron en la UI
    return await repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
