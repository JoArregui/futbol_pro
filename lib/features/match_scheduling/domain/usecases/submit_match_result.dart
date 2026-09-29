import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_result.dart';
import '../repositories/match_repository.dart';

class SubmitMatchResult implements UseCase<MatchResult, SubmitResultParams> {
  final MatchRepository repository;

  SubmitMatchResult(this.repository);

  @override
  Future<Either<Failure, MatchResult>> call(SubmitResultParams params) async {
    if (params.golesA < 0 ||
        params.golesB < 0 ||
        params.golesA > 99 ||
        params.golesB > 99) {
      return const Left(
          ValidationFailure('El marcador debe estar entre 0 y 99.'));
    }
    return repository.submitResult(
      matchId: params.matchId,
      golesA: params.golesA,
      golesB: params.golesB,
      ganador: params.ganador,
      goleadores: params.goleadores,
      teamAIds: params.teamAIds,
      teamBIds: params.teamBIds,
      mvpId: params.mvpId,
    );
  }
}

class SubmitResultParams extends Equatable {
  final String matchId;
  final int golesA;
  final int golesB;
  final String ganador;
  final List<ScorerEntry> goleadores;
  final List<String> teamAIds;
  final List<String> teamBIds;
  final String? mvpId;

  const SubmitResultParams({
    required this.matchId,
    required this.golesA,
    required this.golesB,
    this.ganador = 'empate',
    this.goleadores = const [],
    this.teamAIds = const [],
    this.teamBIds = const [],
    this.mvpId,
  });

  @override
  List<Object?> get props =>
      [matchId, golesA, golesB, ganador, goleadores, teamAIds, teamBIds, mvpId];
}
