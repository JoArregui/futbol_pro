part of 'league_bloc.dart';

abstract class LeagueState extends Equatable {
  const LeagueState();

  @override
  List<Object> get props => [];
}

class LeagueInitial extends LeagueState {}

class LeagueLoading extends LeagueState {}

class LeagueLoadSuccess extends LeagueState {
  final List<Standing> standings;

  const LeagueLoadSuccess({required this.standings});

  @override
  List<Object> get props => [standings];
}

class LeagueError extends LeagueState {
  final String message;

  const LeagueError({required this.message});

  @override
  List<Object> get props => [message];
}
