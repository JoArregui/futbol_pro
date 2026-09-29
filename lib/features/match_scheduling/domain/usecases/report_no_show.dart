import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/match_repository.dart';

class ReportNoShow implements UseCase<int, ReportNoShowParams> {
  final MatchRepository repository;

  ReportNoShow(this.repository);

  @override
  Future<Either<Failure, int>> call(ReportNoShowParams params) async {
    return repository.reportNoShow(
      matchId: params.matchId,
      playerId: params.playerId,
    );
  }
}

class ReportNoShowParams extends Equatable {
  final String matchId;
  final String playerId;

  const ReportNoShowParams({required this.matchId, required this.playerId});

  @override
  List<Object> get props => [matchId, playerId];
}
