import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_data_source.dart';
import '../models/match_model.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource remoteDataSource;
  // Otros Data Sources (local, network checker, etc.)

  MatchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Match>> joinMatch({
    required String matchId,
    required String playerId,
  }) async {
    // 1. (Opcional) Revisar conexión a Internet aquí.

    try {
      final MatchModel matchModel = await remoteDataSource.addPlayerToMatch(
        matchId: matchId,
        playerId: playerId,
      );
      return Right(matchModel); // Devolvemos la Entidad pura del Domain
    } on ConflictException {
      return Left(ConflictFailure(
          message: 'El jugador ya está en el partido o el cupo está lleno.'));
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  // ... (otros métodos)
}