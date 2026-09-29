part of 'league_bloc.dart';

abstract class LeagueEvent extends Equatable {
  const LeagueEvent();

  @override
  List<Object> get props => [];
}

class GetStandingsRequested extends LeagueEvent {
  final String leagueId;

  const GetStandingsRequested({required this.leagueId});

  @override
  List<Object> get props => [leagueId];
}

class GetTournamentsRequested extends LeagueEvent {
  const GetTournamentsRequested();
}

class RegisterTeamRequested extends LeagueEvent {
  final String leagueId;
  final String teamName;

  const RegisterTeamRequested({required this.leagueId, required this.teamName});

  @override
  List<Object> get props => [leagueId, teamName];
}

class CreateLeagueRequested extends LeagueEvent {
  final String nombre;
  final String descripcion;
  final int maxEquipos;

  const CreateLeagueRequested({
    required this.nombre,
    this.descripcion = '',
    this.maxEquipos = 12,
  });

  @override
  List<Object> get props => [nombre, descripcion, maxEquipos];
}

class LeagueDetailRequested extends LeagueEvent {
  final String leagueId;
  final String leagueName;

  const LeagueDetailRequested({required this.leagueId, required this.leagueName});

  @override
  List<Object> get props => [leagueId, leagueName];
}

class GenerateFixtureRequested extends LeagueEvent {
  final String leagueId;

  const GenerateFixtureRequested({required this.leagueId});

  @override
  List<Object> get props => [leagueId];
}