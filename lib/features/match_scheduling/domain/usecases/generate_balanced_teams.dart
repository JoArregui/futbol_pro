import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart'; // Asegúrate de que este archivo contiene ValidationFailure
import '../../../../core/usecases/usecase.dart';
import '../entities/team.dart';
import '../entities/player.dart';


// El resultado del Use Case es un par de equipos
class TeamPair extends Equatable {
  final Team teamA;
  final Team teamB;

  const TeamPair({required this.teamA, required this.teamB});

  @override
  List<Object> get props => [teamA, teamB];
}

class GenerateBalancedTeams implements UseCase<TeamPair, GenerateTeamsParams> {
  // Nota: Aunque este Use Case no necesita el repositorio...
  // final MatchRepository repository;
  // GenerateBalancedTeams(this.repository);

  @override
  Future<Either<Failure, TeamPair>> call(GenerateTeamsParams params) async {
    // 🚨 CORRECCIÓN: Usar ValidationFailure en lugar de InputFailure
    if (params.players.length < 2) {
      return const Left(ValidationFailure("Se requieren al menos 2 jugadores para generar equipos."));
    }
    
    // El Use Case debe verificar si cumple con el mínimo requerido (minPlayers)
    if (params.players.length < params.minPlayers) {
      return Left(ValidationFailure("Se requieren ${params.minPlayers} jugadores para iniciar el partido. Actualmente hay ${params.players.length}."));
    }

    // Algoritmo de balanceo simplificado:
    // 1. Ordenar jugadores por rating.
    // 2. Distribuir los jugadores de mayor a menor rating alternando entre Equipo A y Equipo B.
    
    // Convertir a lista mutable
    List<Player> sortedPlayers = List.from(params.players);
    sortedPlayers.sort((a, b) => b.rating.compareTo(a.rating)); // Orden descendente

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

    // Crear las entidades finales
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

    // El resultado es Right(Success) con los equipos balanceados.
    return Right(TeamPair(teamA: teamA, teamB: teamB));
  }
}

class GenerateTeamsParams extends Equatable {
  final List<Player> players;
  final int minPlayers; // Mínimo necesario (e.g., 10, 14, etc.)
  
  const GenerateTeamsParams({required this.players, required this.minPlayers});

  @override
  List<Object> get props => [players, minPlayers];
}