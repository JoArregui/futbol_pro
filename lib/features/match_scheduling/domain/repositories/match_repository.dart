import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/match.dart';
import '../usecases/generate_balanced_teams.dart'; 

abstract class MatchRepository {
  
  // Soporta ScheduleFriendlyMatch
  Future<Either<Failure, Match>> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
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
}