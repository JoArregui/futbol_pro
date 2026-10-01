part of 'match_bloc.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();
}

class ScheduleFriendlyMatchEvent extends MatchEvent {
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

  const ScheduleFriendlyMatchEvent({
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

class PlayerJoinsMatchEvent extends MatchEvent {
  final String matchId;
  final String playerId;

  const PlayerJoinsMatchEvent({required this.matchId, required this.playerId});

  @override
  List<Object> get props => [matchId, playerId];
}

class GenerateTeamsForMatchEvent extends MatchEvent {
  final String matchId;
  final List<Player> players;

  const GenerateTeamsForMatchEvent({
    required this.matchId,
    required this.players,
  });

  @override
  List<Object> get props => [matchId, players];
}

class GetMatchDetailsEvent extends MatchEvent {
  final String matchId;
  const GetMatchDetailsEvent({required this.matchId});
  @override
  List<Object> get props => [matchId];
}

// ⚽ NUEVO EVENTO
class GetUpcomingMatchesEvent extends MatchEvent {
  const GetUpcomingMatchesEvent();

  @override
  List<Object> get props => [];
}
