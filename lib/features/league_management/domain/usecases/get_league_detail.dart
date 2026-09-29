import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/league_detail.dart';
import '../repositories/league_repository.dart';

class GetLeagueDetail implements UseCase<LeagueDetail, LeagueDetailParams> {
  final LeagueRepository repository;

  GetLeagueDetail(this.repository);

  @override
  Future<Either<Failure, LeagueDetail>> call(LeagueDetailParams params) async {
    return repository.getLeagueDetail(leagueId: params.leagueId);
  }
}

class LeagueDetailParams extends Equatable {
  final String leagueId;

  const LeagueDetailParams({required this.leagueId});

  @override
  List<Object> get props => [leagueId];
}
