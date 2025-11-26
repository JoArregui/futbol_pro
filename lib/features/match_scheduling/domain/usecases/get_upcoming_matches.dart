import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

// Este Use Case solo requiere NoParams y devuelve una lista de Match.
class GetUpcomingMatches implements UseCase<List<Match>, NoParams> {
  final MatchRepository repository;

  GetUpcomingMatches(this.repository);

  @override
  Future<Either<Failure, List<Match>>> call(NoParams params) async {
    return await repository.getUpcomingMatches();
  }
}