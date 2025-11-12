import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/standing.dart';
import '../repositories/league_repository.dart';

class StandingsParams extends Equatable {
  final String leagueId;

  const StandingsParams({required this.leagueId});

  @override
  List<Object> get props => [leagueId];
}

class GetLeagueStandings implements UseCase<List<Standing>, StandingsParams> {
  final LeagueRepository repository;

  GetLeagueStandings(this.repository);

  @override
  Future<Either<Failure, List<Standing>>> call(StandingsParams params) async {
    return await repository.getLeagueStandings(
      leagueId: params.leagueId,
    );
  }
}
