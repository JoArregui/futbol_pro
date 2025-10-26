import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart'; // Importar si existe
import '../../domain/entities/standing.dart';
import '../../domain/repositories/league_repository.dart';
import '../datasources/league_remote_data_source.dart';

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

      // La conversión de List<StandingModel> a List<Standing> es correcta si StandingModel extiende Standing.
      return Right(standingModels);
    } on ServerException {
      // Cambiar de 'Exception' a una específica como ServerException
      // ✅ CORRECCIÓN: Pasar el argumento 'message' al constructor de ServerFailure
      return Left(
        ServerFailure(
          'Fallo al cargar la clasificación de la liga: error de servidor.',
        ),
      );
    } catch (e) {
      // Si quieres atrapar cualquier otra excepción inesperada
      return Left(
        ServerFailure(
          'Error inesperado al obtener la clasificación: ${e.toString()}',
        ),
      );
    }
  }
}
