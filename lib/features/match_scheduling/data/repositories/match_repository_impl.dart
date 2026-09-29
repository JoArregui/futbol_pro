import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/entities/match_split.dart';
import '../../domain/repositories/match_repository.dart';
import '../../domain/usecases/generate_balanced_teams.dart';
import '../datasources/match_remote_datasource.dart';
import '../models/match_model.dart';


class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource remoteDataSource;

  MatchRepositoryImpl({required this.remoteDataSource});

  Either<Failure, T> _handleException<T>(dynamic exception) {
    if (exception is ConflictException) {
      return const Left(
          ValidationFailure('El partido ya está lleno o ya te has inscrito.'));
    } else if (exception is UnauthorizedException) {
      return const Left(
          AuthenticationFailure('No autorizado. Por favor, inicia sesión.'));
    } else if (exception is ForbiddenException) {
      return const Left(
          PermissionFailure('No tienes permiso para realizar esta acción.'));
    } else if (exception is NotFoundException) {
      return const Left(
          NotFoundFailure('El recurso solicitado no fue encontrado.'));
    } else if (exception is ServerException) {
      return const Left(
          ServerFailure('Error en el servidor. Inténtalo de nuevo más tarde.'));
    } else {
      return const Left(ServerFailure('Ocurrió un error inesperado.'));
    }
  }

  // Soporta JoinMatch
  @override
  Future<Either<Failure, Match>> joinMatch({
    required String matchId,
    required String playerId,
  }) async {
    try {
      final MatchModel matchModel = await remoteDataSource.addPlayerToMatch(
        matchId: matchId,
        playerId: playerId,
      );
      return Right(matchModel);
    } catch (e) {
      return _handleException(e);
    }
  }

  // Soporta ScheduleFriendlyMatch
  @override
  Future<Either<Failure, Match>> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
    String title = 'Amistoso',
    String mode = 'open',
    bool needsReferee = false,
    String? description,
    String? organizerTeamName,
    String? opponentTeamName,
    int? maxPlayers,
    double? costeTotal,
  }) async {
    try {
      final MatchModel matchModel =
          await remoteDataSource.scheduleFriendlyMatch(
        time: time,
        fieldId: fieldId,
        title: title,
        mode: mode,
        needsReferee: needsReferee,
        description: description,
        organizerTeamName: organizerTeamName,
        opponentTeamName: opponentTeamName,
        maxPlayers: maxPlayers,
        costeTotal: costeTotal,
      );
      return Right(matchModel);
    } catch (e) {
      return _handleException(e);
    }
  }

  // Soporta GetUpcomingMatches
  @override
  Future<Either<Failure, List<Match>>> getUpcomingMatches() async {
    try {
      final List<MatchModel> matchModels =
          await remoteDataSource.getUpcomingMatches();
      return Right(matchModels);
    } catch (e) {
      return _handleException(e);
    }
  }

  // Soporta GetMatchDetails (mediante getMatchById)
  @override
  Future<Either<Failure, Match>> getMatchById(String matchId) async {
    try {
      final MatchModel matchModel =
          await remoteDataSource.getMatchById(matchId);
      return Right(matchModel);
    } catch (e) {
      return _handleException(e);
    }
  }

  // Soporta UpdateMatchWithTeams
  @override
  Future<Either<Failure, Match>> updateMatchWithTeams({
    required String matchId,
    required TeamPair teamPair,
  }) async {
    try {
      // ⚠️ Asumo que las entidades Team tienen un método toModel()
      final MatchModel matchModel = await remoteDataSource.updateMatchTeams(
        matchId: matchId,
        teamA: teamPair.teamA.toModel(),
        teamB: teamPair.teamB.toModel(),
      );
      return Right(matchModel);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Either<Failure, MatchResult>> submitResult({
    required String matchId,
    required int golesA,
    required int golesB,
    String ganador = 'empate',
    List<ScorerEntry> goleadores = const [],
    List<String> teamAIds = const [],
    List<String> teamBIds = const [],
    String? mvpId,
  }) async {
    try {
      final result = await remoteDataSource.submitResult(
        matchId: matchId,
        golesA: golesA,
        golesB: golesB,
        ganador: ganador,
        goleadores: goleadores,
        teamAIds: teamAIds,
        teamBIds: teamBIds,
        mvpId: mvpId,
      );
      return Right(result);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Either<Failure, MatchResult>> confirmResult({
    required String matchId,
  }) async {
    try {
      final result = await remoteDataSource.confirmResult(matchId: matchId);
      return Right(result);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Either<Failure, int>> reportNoShow({
    required String matchId,
    required String playerId,
  }) async {
    try {
      final count = await remoteDataSource.reportNoShow(
          matchId: matchId, playerId: playerId);
      return Right(count);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Either<Failure, MatchSplit>> getSplit({
    required String matchId,
  }) async {
    try {
      final split = await remoteDataSource.getSplit(matchId: matchId);
      return Right(split);
    } catch (e) {
      return _handleException(e);
    }
  }
}