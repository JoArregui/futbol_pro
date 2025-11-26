part of 'match_bloc.dart';

abstract class MatchState extends Equatable {
  const MatchState();

  @override
  List<Object> get props => [];
}

class MatchInitial extends MatchState {}

class MatchLoading extends MatchState {}

class MatchLoaded extends MatchState {
  final Match match;
  const MatchLoaded({required this.match});

  @override
  List<Object> get props => [match];
}

// ⚽ NUEVO ESTADO para la lista
class MatchesListLoaded extends MatchState {
  final List<Match> matches;
  const MatchesListLoaded({required this.matches});

  @override
  List<Object> get props => [matches];
}


class MatchScheduledSuccess extends MatchState {
  final Match match;
  const MatchScheduledSuccess(this.match);

  @override
  List<Object> get props => [match];
}

class MatchError extends MatchState {
  final String message;
  const MatchError(this.message);

  @override
  List<Object> get props => [message];
}

class TeamsGeneratedSuccess extends MatchState {
  final TeamPair teamPair;

  const TeamsGeneratedSuccess({required this.teamPair});

  @override
  List<Object> get props => [teamPair];
}