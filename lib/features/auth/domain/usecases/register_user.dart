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
    // Aquí podrías añadir lógica de validación previa al repositorio
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
  final String? name; // Opcional, si no lo pides en el formulario
  // Si tu API lo requiere, puedes añadir aquí más campos

  const RegisterParams({
    required this.email, 
    required this.password, 
    required this.nickname,
    this.name, // Deja 'name' como opcional para simplificar la llamada
  });

  @override
  List<Object?> get props => [email, password, nickname, name];
}
