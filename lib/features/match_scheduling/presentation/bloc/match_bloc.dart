import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/player.dart';
import '../../domain/usecases/generate_balanced_teams.dart';
import '../../domain/usecases/join_match.dart';

part 'match_event.dart';
part 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final JoinMatch joinMatch;
  final GenerateBalancedTeams generateBalancedTeams;
  // ... (otros Use Cases)

  MatchBloc({required this.joinMatch}) : super(MatchInitial()) {
    on<PlayerJoinsMatchEvent>(_onPlayerJoinsMatch);
    required this.generateBalancedTeams, // Inyectar
  }) : super(MatchInitial()) {
    on<PlayerJoinsMatchEvent>(_onPlayerJoinsMatch);
    on<GenerateTeamsForMatchEvent>(_onGenerateTeamsForMatch);
    // ... (otros on<Events>)
  }

  Future<void> _onPlayerJoinsMatch(
    PlayerJoinsMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    // Usamos la Inyección de Dependencias para llamar al Use Case
    final failureOrMatch = await joinMatch(
      JoinMatchParams(
        matchId: event.matchId,
        playerId: event.playerId,
      ),
    );

    failureOrMatch.fold(
      (failure) => emit(MatchError(mapFailureToMessage(failure))),
      (match) => emit(MatchScheduledSuccess(match)), // Reutilizamos este estado para mostrar el partido actualizado
    );
  }

  Future<void> _onGenerateTeamsForMatch(
    GenerateTeamsForMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading()); // Podrías usar un estado de carga más específico

    // 1. Ejecutar el Use Case de balanceo de equipos
    final failureOrTeams = await generateBalancedTeams(
      GenerateTeamsParams(
        players: event.players, 
        minPlayers: 10, // Ejemplo: asumir 10 jugadores como mínimo
      ),
    );

    failureOrTeams.fold(
      (failure) => emit(MatchError(mapFailureToMessage(failure))),
      (teamPair) {
        // 2. Si es exitoso, ahora hay que actualizar el Match en el backend
        // Aquí llamarías a otro Use Case: UpdateMatchWithTeams(matchId: event.matchId, teamA: teamPair.teamA, teamB: teamPair.teamB)
        
        // **IMPORTANTE:** Este Use Case final de actualización DEBE disparar la NOTIFICACIÓN PUSH
        // a los jugadores que se han apuntado, avisando que los equipos están listos.

        emit(TeamsGeneratedSuccess(teamPair: teamPair)); // Nuevo estado de éxito (ver abajo)
      },
    );
  }
}