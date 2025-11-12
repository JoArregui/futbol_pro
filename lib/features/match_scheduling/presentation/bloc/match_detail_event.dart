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