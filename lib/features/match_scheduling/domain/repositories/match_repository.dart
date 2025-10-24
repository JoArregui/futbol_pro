import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/match.dart';

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
}