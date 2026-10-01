part of 'match_detail_bloc.dart';

abstract class MatchDetailEvent extends Equatable {
  const MatchDetailEvent();

  @override
  List<Object> get props => [];
}

class MatchDetailLoadRequested extends MatchDetailEvent {
  final String matchId;

  const MatchDetailLoadRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class MatchResultProposeRequested extends MatchDetailEvent {
  final SubmitResultParams params;

  const MatchResultProposeRequested(this.params);

  @override
  List<Object> get props => [params];
}

class MatchResultConfirmRequested extends MatchDetailEvent {
  final String matchId;

  const MatchResultConfirmRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class MatchNoShowReported extends MatchDetailEvent {
  final String matchId;
  final String playerId;

  const MatchNoShowReported({required this.matchId, required this.playerId});

  @override
  List<Object> get props => [matchId, playerId];
}

class MatchSplitRequested extends MatchDetailEvent {
  final String matchId;

  const MatchSplitRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}

class MatchActaRequested extends MatchDetailEvent {
  final String matchId;

  const MatchActaRequested(this.matchId);

  @override
  List<Object> get props => [matchId];
}
