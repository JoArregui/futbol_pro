import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/team.dart';
import '../entities/player.dart';

class TeamPair extends Equatable {
  final Team teamA;
  final Team teamB;

  const TeamPair({required this.teamA, required this.teamB});

  @override
  List<Object> get props => [teamA, teamB];
}

class GenerateBalancedTeams implements UseCase<TeamPair, GenerateTeamsParams> {
  @override
  Future<Either<Failure, TeamPair>> call(GenerateTeamsParams params) async {
    if (params.players.length < 2) {
      return const Left(ValidationFailure(
          "Se requieren al menos 2 jugadores para generar equipos."));
    }

    if (params.players.length < params.minPlayers) {
      return Left(ValidationFailure(
          "Se requieren ${params.minPlayers} jugadores para iniciar el partido. Actualmente hay ${params.players.length}."));
    }

    // Algoritmo de balanceo simplificado:
    // 1. Ordenar jugadores por rating.
    // 2. Distribuir los jugadores de mayor a menor rating alternando entre Equipo A y Equipo B.

    List<Player> sortedPlayers = List.from(params.players);
    sortedPlayers.sort((a, b) => b.rating.compareTo(a.rating));

    List<Player> teamAPlayers = [];
    List<Player> teamBPlayers = [];
    double ratingA = 0.0;
    double ratingB = 0.0;

    for (int i = 0; i < sortedPlayers.length; i++) {
      Player player = sortedPlayers[i];
      if (i % 2 == 0) {
        teamAPlayers.add(player);
        ratingA += player.rating;
      } else {
        teamBPlayers.add(player);
        ratingB += player.rating;
      }
    }

    final teamA = Team(
      name: 'Equipo A',
      players: teamAPlayers,
      combinedRating: ratingA,
    );
    final teamB = Team(
      name: 'Equipo B',
      players: teamBPlayers,
      combinedRating: ratingB,
    );

    return Right(TeamPair(teamA: teamA, teamB: teamB));
  }
}

class GenerateTeamsParams extends Equatable {
  final List<Player> players;
  final int minPlayers;

  const GenerateTeamsParams({required this.players, required this.minPlayers});

  @override
  List<Object> get props => [players, minPlayers];
}
