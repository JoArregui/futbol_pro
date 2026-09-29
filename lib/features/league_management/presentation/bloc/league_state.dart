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

class TournamentsLoaded extends LeagueState {
  final List<Tournament> tournaments;

  const TournamentsLoaded({required this.tournaments});

  @override
  List<Object> get props => [tournaments];
}

class TeamRegistered extends LeagueState {
  final String leagueId;

  const TeamRegistered({required this.leagueId});

  @override
  List<Object> get props => [leagueId];
}

class LeagueCreated extends LeagueState {
  final Tournament league;

  const LeagueCreated({required this.league});

  @override
  List<Object> get props => [league];
}

class LeagueDetailLoaded extends LeagueState {
  final String leagueId;
  final String leagueName;
  final LeagueDetail detail;

  const LeagueDetailLoaded({
    required this.leagueId,
    required this.leagueName,
    required this.detail,
  });

  @override
  List<Object> get props => [leagueId, leagueName, detail];
}

class FixtureGenerated extends LeagueState {
  final String leagueId;
  final int jornadas;
  final int partidos;

  const FixtureGenerated({
    required this.leagueId,
    required this.jornadas,
    required this.partidos,
  });

  @override
  List<Object> get props => [leagueId, jornadas, partidos];
}