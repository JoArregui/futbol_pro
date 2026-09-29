import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tournament.dart';
import '../repositories/league_repository.dart';

class GetTournaments implements UseCase<List<Tournament>, NoParams> {
  final LeagueRepository repository;
  GetTournaments(this.repository);

  @override
  Future<Either<Failure, List<Tournament>>> call(NoParams params) =>
      repository.getTournaments();
}
