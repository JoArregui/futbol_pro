import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

// El resultado del Use Case es un objeto Match
class GetMatchDetails implements UseCase<Match, GetMatchDetailsParams> {
  final MatchRepository repository;

  GetMatchDetails(this.repository);

  @override
  Future<Either<Failure, Match>> call(GetMatchDetailsParams params) async {
    // Delega la responsabilidad de obtener los datos al repositorio
    return await repository.getMatchById(params.matchId);
  }
}

class GetMatchDetailsParams extends Equatable {
  final String matchId;

  const GetMatchDetailsParams({required this.matchId});

  @override
  List<Object> get props => [matchId];
}