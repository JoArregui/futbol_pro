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