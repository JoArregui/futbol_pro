import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match.dart';
import '../repositories/match_repository.dart';

class ScheduleFriendlyMatchParams extends Equatable {
  final DateTime time;
  final String fieldId;
  final String title;
  final String mode;
  final bool needsReferee;
  final String? description;
  final String? organizerTeamName;
  final String? opponentTeamName;
  final int? maxPlayers;
  final double? costeTotal;

  const ScheduleFriendlyMatchParams({
    required this.time,
    required this.fieldId,
    this.title = 'Amistoso',
    this.mode = 'open',
    this.needsReferee = false,
    this.description,
    this.organizerTeamName,
    this.opponentTeamName,
    this.maxPlayers,
    this.costeTotal,
  });

  @override
  List<Object?> get props => [
        time,
        fieldId,
        title,
        mode,
        needsReferee,
        description,
        organizerTeamName,
        opponentTeamName,
        maxPlayers,
        costeTotal,
      ];
}

class ScheduleFriendlyMatch
    implements UseCase<Match, ScheduleFriendlyMatchParams> {
  final MatchRepository repository;

  ScheduleFriendlyMatch(this.repository);

  @override
  Future<Either<Failure, Match>> call(
      ScheduleFriendlyMatchParams params) async {
    return await repository.scheduleFriendlyMatch(
      time: params.time,
      fieldId: params.fieldId,
      title: params.title,
      mode: params.mode,
      needsReferee: params.needsReferee,
      description: params.description,
      organizerTeamName: params.organizerTeamName,
      opponentTeamName: params.opponentTeamName,
      maxPlayers: params.maxPlayers,
      costeTotal: params.costeTotal,
    );
  }
}
