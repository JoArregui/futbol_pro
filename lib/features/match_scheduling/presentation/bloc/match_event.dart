part of 'match_bloc.dart';

abstract class MatchEvent extends Equatable {
  const MatchEvent();
}

class ScheduleFriendlyMatchEvent extends MatchEvent {
  final DateTime time;
  final String fieldId;

  const ScheduleFriendlyMatchEvent({required this.time, required this.fieldId});

  @override
  List<Object> get props => [time, fieldId];
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