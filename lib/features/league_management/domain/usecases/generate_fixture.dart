import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/league_repository.dart';

class GenerateFixture
    implements UseCase<Map<String, dynamic>, GenerateFixtureParams> {
  final LeagueRepository repository;

  GenerateFixture(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      GenerateFixtureParams params) async {
    return repository.generateFixture(leagueId: params.leagueId);
  }
}

class GenerateFixtureParams extends Equatable {
  final String leagueId;

  const GenerateFixtureParams({required this.leagueId});

  @override
  List<Object> get props => [leagueId];
}
