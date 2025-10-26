part of 'league_bloc.dart';

abstract class LeagueEvent extends Equatable {
  const LeagueEvent();
}

class GetStandingsRequested extends LeagueEvent {
  final String leagueId; // Para ligas múltiples

  const GetStandingsRequested({required this.leagueId});

  @override
  List<Object> get props => [leagueId];
}
