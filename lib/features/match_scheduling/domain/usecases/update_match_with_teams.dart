import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';
import 'generate_balanced_teams.dart'; // Importa TeamPair

// El resultado del Use Case es el Match actualizado
class UpdateMatchWithTeams implements UseCase<Match, UpdateMatchWithTeamsParams> {
  final MatchRepository repository;

  UpdateMatchWithTeams(this.repository);

  @override
  Future<Either<Failure, Match>> call(UpdateMatchWithTeamsParams params) async {
    // El repositorio implementará la lógica de guardado en el backend
    return await repository.updateMatchWithTeams(
      matchId: params.matchId, 
      teamPair: params.teamPair,
    );
  }
}

class UpdateMatchWithTeamsParams extends Equatable {
  final String matchId;
  final TeamPair teamPair;

  const UpdateMatchWithTeamsParams({
    required this.matchId, 
    required this.teamPair,
  });

  @override
  List<Object> get props => [matchId, teamPair];
}