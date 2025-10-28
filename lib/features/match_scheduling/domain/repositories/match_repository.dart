import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/match.dart';
import '../usecases/generate_balanced_teams.dart'; 

abstract class MatchRepository {
 Future<Either<Failure, Match>> scheduleFriendlyMatch({
  required DateTime time,
  required String fieldId,
 });
 
 Future<Either<Failure, List<Match>>> getUpcomingMatches();
 
 Future<Either<Failure, Match>> joinMatch({
  required String matchId,
  required String playerId,
 });
 

 Future<Either<Failure, Match>> getMatchById(String matchId);
 

 Future<Either<Failure, Match>> updateMatchWithTeams({
  required String matchId,
  required TeamPair teamPair,
 });
}