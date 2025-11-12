import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

class JoinMatch implements UseCase<Match, JoinMatchParams> {
  final MatchRepository repository;

  JoinMatch(this.repository);

  @override
  Future<Either<Failure, Match>> call(JoinMatchParams params) async {
    return await repository.joinMatch(
      matchId: params.matchId,
      playerId: params.playerId,
    );
  }
}

class JoinMatchParams extends Equatable {
  final String matchId;
  final String playerId;

  const JoinMatchParams({required this.matchId, required this.playerId});

  @override
  List<Object> get props => [matchId, playerId];
}
