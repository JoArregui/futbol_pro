import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/league_detail.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/repositories/league_repository.dart';
import '../datasources/league_remote_datasource.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  final LeagueRemoteDataSource remoteDataSource;

  LeagueRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Standing>>> getLeagueStandings({
    required String leagueId,
  }) async {
    try {
      final standingModels = await remoteDataSource.fetchLeagueStandings(
        leagueId: leagueId,
      );

      return Right(standingModels);
    } on ServerException {
      return const Left(
        ServerFailure(
          'Fallo al cargar la clasificación de la liga: error de servidor.',
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure(
          'Error inesperado al obtener la clasificación: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Tournament>>> getTournaments() async {
    try {
      final models = await remoteDataSource.fetchTournaments();
      return Right(List<Tournament>.from(models));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> registerTeam(
      {required String leagueId, required String teamName}) async {
    try {
      final ok = await remoteDataSource.registerTeam(
          leagueId: leagueId, teamName: teamName);
      return Right(ok);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Tournament>> createLeague({
    required String nombre,
    String descripcion = '',
    int maxEquipos = 12,
  }) async {
    try {
      final model = await remoteDataSource.createLeague(
          nombre: nombre, descripcion: descripcion, maxEquipos: maxEquipos);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, LeagueDetail>> getLeagueDetail({
    required String leagueId,
  }) async {
    try {
      // Carga paralela: equipos + fixture + tabla + goleadores.
      final results = await Future.wait([
        remoteDataSource.fetchLeagueTeams(leagueId: leagueId),
        remoteDataSource.fetchFixture(leagueId: leagueId),
        remoteDataSource.fetchLeagueStandings(leagueId: leagueId),
        remoteDataSource.fetchScorers(leagueId: leagueId),
      ]);
      return Right(LeagueDetail(
        teams: results[0] as List<LeagueTeam>,
        fixture: results[1] as List<FixtureEntry>,
        standings: (results[2] as List).cast<Standing>(),
        scorers: results[3] as List<ScorerRow>,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> generateFixture({
    required String leagueId,
  }) async {
    try {
      final res =
          await remoteDataSource.generateFixture(leagueId: leagueId);
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }
}
