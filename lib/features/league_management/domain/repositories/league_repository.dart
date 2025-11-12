import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/standing.dart';

abstract class LeagueRepository {
  Future<Either<Failure, List<Standing>>> getLeagueStandings({
    required String leagueId,
  });
}
