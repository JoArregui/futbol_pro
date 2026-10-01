import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/match.dart';
import '../entities/match_acta.dart';
import '../entities/match_result.dart';
import '../entities/match_split.dart';
import '../usecases/generate_balanced_teams.dart';

abstract class MatchRepository {
  // Soporta ScheduleFriendlyMatch (amistoso: sueltos o equipos + árbitro)
  Future<Either<Failure, Match>> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
    String title = 'Amistoso',
    String mode = 'open',
    bool needsReferee = false,
    String? description,
    String? organizerTeamName,
    String? opponentTeamName,
    int? maxPlayers,
    double? costeTotal,
  });

  // Soporta GetUpcomingMatches
  Future<Either<Failure, List<Match>>> getUpcomingMatches();

  // Soporta JoinMatch
  Future<Either<Failure, Match>> joinMatch({
    required String matchId,
    required String playerId,
  });

  // Soporta GetMatchDetails (tu use case, que usa getMatchById)
  Future<Either<Failure, Match>> getMatchById(String matchId);

  // Soporta UpdateMatchWithTeams
  Future<Either<Failure, Match>> updateMatchWithTeams({
    required String matchId,
    required TeamPair teamPair,
  });

  // Resultado final + reputación
  Future<Either<Failure, MatchResult>> submitResult({
    required String matchId,
    required int golesA,
    required int golesB,
    String ganador,
    List<ScorerEntry> goleadores,
    List<String> teamAIds,
    List<String> teamBIds,
    String? mvpId,
  });

  Future<Either<Failure, MatchResult>> confirmResult({
    required String matchId,
  });

  Future<Either<Failure, int>> reportNoShow({
    required String matchId,
    required String playerId,
  });

  Future<Either<Failure, MatchSplit>> getSplit({
    required String matchId,
  });

  Future<Either<Failure, MatchActa>> getActa({
    required String matchId,
  });
}
