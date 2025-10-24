import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

// Este Use Case devuelve el Match actualizado
class JoinMatch implements UseCase<Match, JoinMatchParams> {
  final MatchRepository repository;

  JoinMatch(this.repository);

  @override
  Future<Either<Failure, Match>> call(JoinMatchParams params) async {
    // La lógica de negocio aquí podría incluir:
    // 1. Verificar si el usuario ya está en el partido (o si hay cupo).
    // 2. Si el partido es Friendly y llega al cupo mínimo, puede disparar
    //    una alerta al sistema para balancear los equipos (otro Use Case).

    return await repository.joinMatch(
      matchId: params.matchId,
      playerId: params.playerId,
    );
  }
}

class JoinMatchParams extends Equatable {
  final String matchId;
  final String playerId; // Obtenido del módulo de Auth/Usuario actual

  const JoinMatchParams({required this.matchId, required this.playerId});

  @override
  List<Object> get props => [matchId, playerId];
}