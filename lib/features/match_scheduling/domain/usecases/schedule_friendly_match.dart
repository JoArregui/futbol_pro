import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

// Params para el Use Case
class ScheduleFriendlyMatchParams extends Equatable {
  final DateTime time;
  final String fieldId;

  const ScheduleFriendlyMatchParams({required this.time, required this.fieldId});

  @override
  List<Object> get props => [time, fieldId];
}

// El Use Case
class ScheduleFriendlyMatch implements UseCase<Match, ScheduleFriendlyMatchParams> {
  final MatchRepository repository;

  ScheduleFriendlyMatch(this.repository);

  @override
  Future<Either<Failure, Match>> call(ScheduleFriendlyMatchParams params) async {
    return await repository.scheduleFriendlyMatch(
      time: params.time,
      fieldId: params.fieldId,
    );
  }
}