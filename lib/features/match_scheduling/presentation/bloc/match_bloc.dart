import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/player.dart';
import '../../domain/usecases/generate_balanced_teams.dart';
import '../../domain/usecases/join_match.dart';
import '../../domain/usecases/schedule_friendly_match.dart';
import '../../domain/usecases/get_match_details.dart';
import '../../domain/usecases/update_match_with_teams.dart';
// ⚽ NUEVO IMPORT
import '../../domain/usecases/get_upcoming_matches.dart'; 
import '../../../../core/usecases/usecase.dart'; // Importar NoParams

part 'match_event.dart';
part 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final JoinMatch joinMatch;
  final GenerateBalancedTeams generateBalancedTeams;
  final ScheduleFriendlyMatch scheduleFriendlyMatch;
  final GetMatchDetails getMatchDetails;
  final UpdateMatchWithTeams updateMatchWithTeams;
  // ⚽ NUEVO USE CASE
  final GetUpcomingMatches getUpcomingMatches;

  MatchBloc({
    required this.joinMatch,
    required this.generateBalancedTeams,
    required this.scheduleFriendlyMatch,
    required this.getMatchDetails,
    required this.updateMatchWithTeams,
    // ⚽ INYECTAR NUEVO USE CASE
    required this.getUpcomingMatches,
  }) : super(MatchInitial()) {
    on<ScheduleFriendlyMatchEvent>(_onScheduleFriendlyMatch);
    on<PlayerJoinsMatchEvent>(_onPlayerJoinsMatch);
    on<GenerateTeamsForMatchEvent>(_onGenerateTeamsForMatch);
    on<GetMatchDetailsEvent>(_onGetMatchDetails);
    // ⚽ REGISTRAR NUEVO MANEJADOR
    on<GetUpcomingMatchesEvent>(_onGetUpcomingMatches); 
  }

  // ⚽ NUEVO MANEJADOR DE EVENTO
  Future<void> _onGetUpcomingMatches(
    GetUpcomingMatchesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    final failureOrMatches = await getUpcomingMatches(NoParams());

    failureOrMatches.fold(
      (failure) => emit(MatchError(failure.errorMessage)),
      (matches) => emit(MatchesListLoaded(matches: matches)),
    );
  }
  
  Future<void> _onGetMatchDetails(
    GetMatchDetailsEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    final failureOrMatch = await getMatchDetails(
      GetMatchDetailsParams(matchId: event.matchId),
    );

    failureOrMatch.fold(
      (failure) => emit(MatchError(failure.errorMessage)),
      (match) => emit(MatchLoaded(match: match)),
    );
  }

  Future<void> _onScheduleFriendlyMatch(
    ScheduleFriendlyMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    final failureOrMatch = await scheduleFriendlyMatch(
      ScheduleFriendlyMatchParams(
        time: event.time,
        fieldId: event.fieldId,
      ),
    );

    failureOrMatch.fold(
      (failure) => emit(MatchError(failure.errorMessage)),
      (match) => emit(MatchScheduledSuccess(match)),
    );
  }

  Future<void> _onPlayerJoinsMatch(
    PlayerJoinsMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    final failureOrMatch = await joinMatch(
      JoinMatchParams(
        matchId: event.matchId,
        playerId: event.playerId,
      ),
    );

    failureOrMatch.fold(
      (failure) => emit(MatchError(failure.errorMessage)),
      (match) => emit(MatchScheduledSuccess(match)),
    );
  }

  Future<void> _onGenerateTeamsForMatch(
    GenerateTeamsForMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    final failureOrTeams = await generateBalancedTeams(
      GenerateTeamsParams(
        players: event.players,
        minPlayers: 10,
      ),
    );

    await failureOrTeams.fold(
      (failure) async => emit(MatchError(failure.errorMessage)),
      (teamPair) async {
        final failureOrUpdatedMatch = await updateMatchWithTeams(
          UpdateMatchWithTeamsParams(
            matchId: event.matchId,
            teamPair: teamPair,
          ),
        );

        failureOrUpdatedMatch.fold(
          (failure) => emit(MatchError(failure.errorMessage)),
          (updatedMatch) => emit(MatchScheduledSuccess(updatedMatch)),
        );
      },
    );
  }
}