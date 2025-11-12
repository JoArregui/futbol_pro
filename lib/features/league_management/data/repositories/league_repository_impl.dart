import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/standing.dart';
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
}
