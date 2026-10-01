import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_acta.dart';
import '../repositories/match_repository.dart';

class GetMatchActa implements UseCase<MatchActa, MatchActaParams> {
  final MatchRepository repository;

  GetMatchActa(this.repository);

  @override
  Future<Either<Failure, MatchActa>> call(MatchActaParams params) async {
    return repository.getActa(matchId: params.matchId);
  }
}

class MatchActaParams extends Equatable {
  final String matchId;

  const MatchActaParams({required this.matchId});

  @override
  List<Object> get props => [matchId];
}
