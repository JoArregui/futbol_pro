import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_result.dart';
import '../repositories/match_repository.dart';

class ConfirmMatchResult
    implements UseCase<MatchResult, ConfirmResultParams> {
  final MatchRepository repository;

  ConfirmMatchResult(this.repository);

  @override
  Future<Either<Failure, MatchResult>> call(ConfirmResultParams params) async {
    return repository.confirmResult(matchId: params.matchId);
  }
}

class ConfirmResultParams extends Equatable {
  final String matchId;

  const ConfirmResultParams({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
