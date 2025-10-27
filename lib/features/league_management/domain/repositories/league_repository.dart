import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/standing.dart';

abstract class LeagueRepository {
  /// Obtiene la clasificación (tabla de posiciones) de una liga específica.
  /// 
  /// Retorna un [Failure] si hay un problema (servidor, conexión, etc.)
  /// o una lista de [Standing] si es exitoso.
  Future<Either<Failure, List<Standing>>> getLeagueStandings({
    required String leagueId,
  });
}
