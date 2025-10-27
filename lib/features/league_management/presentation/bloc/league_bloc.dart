import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart'; 

// Importaciones de dominio y core
import '../../../../core/errors/failures.dart';
import '../../domain/entities/standing.dart';
import '../../domain/usecases/get_league_standings.dart';

part 'league_event.dart';
part 'league_state.dart';

class LeagueBloc extends Bloc<LeagueEvent, LeagueState> {
  final GetLeagueStandings getLeagueStandings;

  LeagueBloc({
    required this.getLeagueStandings,
  }) : super(LeagueInitial()) {
    on<GetStandingsRequested>(_onGetStandingsRequested);
  }

  Future<void> _onGetStandingsRequested(
    GetStandingsRequested event,
    Emitter<LeagueState> emit,
  ) async {
    emit(LeagueLoading());

    final failureOrStandings = await getLeagueStandings(
      StandingsParams(leagueId: event.leagueId),
    );

    failureOrStandings.fold(
      (failure) {
        emit(LeagueError(message: failure.errorMessage));
      },
      (standings) {
        emit(LeagueLoadSuccess(standings: standings));
      },
    );
  }
}