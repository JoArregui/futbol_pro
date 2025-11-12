import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/player.dart';
import '../repositories/auth_repository.dart';
import 'package:futbol_pro/core/usecases/usecase.dart';

class RegisterUser implements UseCase<Player, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, Player>> call(RegisterParams params) async {
    return await repository.register(
      email: params.email,
      password: params.password,
      nickname: params.nickname,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String nickname;
  final String? name;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.nickname,
    this.name,
  });

  @override
  List<Object?> get props => [email, password, nickname, name];
}
