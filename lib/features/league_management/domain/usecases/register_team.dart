import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/league_repository.dart';

class RegisterTeamParams extends Equatable {
  final String leagueId;
  final String teamName;
  const RegisterTeamParams({required this.leagueId, required this.teamName});
  @override
  List<Object> get props => [leagueId, teamName];
}

class RegisterTeam implements UseCase<bool, RegisterTeamParams> {
  final LeagueRepository repository;
  RegisterTeam(this.repository);

  @override
  Future<Either<Failure, bool>> call(RegisterTeamParams params) =>
      repository.registerTeam(
          leagueId: params.leagueId, teamName: params.teamName);
}
