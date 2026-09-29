import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_split.dart';
import '../repositories/match_repository.dart';

class GetMatchSplit implements UseCase<MatchSplit, MatchSplitParams> {
  final MatchRepository repository;

  GetMatchSplit(this.repository);

  @override
  Future<Either<Failure, MatchSplit>> call(MatchSplitParams params) async {
    return repository.getSplit(matchId: params.matchId);
  }
}

class MatchSplitParams extends Equatable {
  final String matchId;

  const MatchSplitParams({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
