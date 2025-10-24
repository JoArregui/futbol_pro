import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

// Params para el Use Case
class Params extends Equatable {
  final DateTime time;
  final String fieldId;

  const Params({required this.time, required this.fieldId});

  @override
  List<Object> get props => [time, fieldId];
}

// El Use Case
class ScheduleFriendlyMatch implements UseCase<Match, Params> {
  final MatchRepository repository;

  ScheduleFriendlyMatch(this.repository);

  @override
  Future<Either<Failure, Match>> call(Params params) async {
    return await repository.scheduleFriendlyMatch(
      time: params.time,
      fieldId: params.fieldId,
    );
  }
}