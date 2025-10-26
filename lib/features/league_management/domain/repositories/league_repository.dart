import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/standing.dart';

abstract class LeagueRepository {
  /// Obtiene la clasificación completa de una liga.
  Future<Either<Failure, List<Standing>>> getLeagueStandings({
    required String leagueId,
  });
}
