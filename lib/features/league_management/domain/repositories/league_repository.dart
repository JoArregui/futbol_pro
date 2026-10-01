import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/league_detail.dart';
import '../entities/standing.dart';
import '../entities/tournament.dart';

abstract class LeagueRepository {
  Future<Either<Failure, List<Standing>>> getLeagueStandings({
    required String leagueId,
  });
  Future<Either<Failure, List<Tournament>>> getTournaments();
  Future<Either<Failure, bool>> registerTeam({
    required String leagueId,
    required String teamName,
  });
  Future<Either<Failure, Tournament>> createLeague({
    required String nombre,
    String descripcion,
    int maxEquipos,
  });
  Future<Either<Failure, LeagueDetail>> getLeagueDetail({
    required String leagueId,
  });
  Future<Either<Failure, Map<String, dynamic>>> generateFixture({
    required String leagueId,
  });
}
