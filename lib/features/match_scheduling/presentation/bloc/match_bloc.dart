import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart'; // Importa todas las Failures y la extensión errorMessage
import '../../domain/entities/match.dart'; // Necesario si MatchScheduledSuccess usa Match
import '../../domain/entities/player.dart';
import '../../domain/usecases/generate_balanced_teams.dart'; // Incluye GenerateTeamsParams y TeamPair
import '../../domain/usecases/join_match.dart'; // Incluye JoinMatchParams
import '../../domain/usecases/schedule_friendly_match.dart'; // Incluye ScheduleFriendlyMatchParams

part 'match_event.dart';
part 'match_state.dart';

class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final JoinMatch joinMatch;
  final GenerateBalancedTeams generateBalancedTeams;
  final ScheduleFriendlyMatch scheduleFriendlyMatch;

  MatchBloc({
    required this.joinMatch,
    required this.generateBalancedTeams,
    required this.scheduleFriendlyMatch,
  }) : super(MatchInitial()) {
    // Definición de manejadores de eventos
    on<ScheduleFriendlyMatchEvent>(_onScheduleFriendlyMatch);
    on<PlayerJoinsMatchEvent>(_onPlayerJoinsMatch);
    on<GenerateTeamsForMatchEvent>(_onGenerateTeamsForMatch);
  }

  // ===========================================
  // MANEJADOR: ScheduleFriendlyMatchEvent
  // ===========================================
  Future<void> _onScheduleFriendlyMatch(
    ScheduleFriendlyMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    final failureOrMatch = await scheduleFriendlyMatch(
      // ✅ Usa la clase de parámetros importada
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

  // ===========================================
  // MANEJADOR: PlayerJoinsMatchEvent
  // ===========================================
  Future<void> _onPlayerJoinsMatch(
    PlayerJoinsMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    final failureOrMatch = await joinMatch(
      // ✅ Usa la clase de parámetros importada
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

  // ===========================================
  // MANEJADOR: GenerateTeamsForMatchEvent
  // ===========================================
  Future<void> _onGenerateTeamsForMatch(
    GenerateTeamsForMatchEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(MatchLoading());

    // 1. Ejecutar el Use Case de balanceo de equipos
    final failureOrTeams = await generateBalancedTeams(
      // ✅ Usa la clase de parámetros importada
      GenerateTeamsParams(
        players: event.players,
        minPlayers: 10,
      ),
    );

    failureOrTeams.fold(
      (failure) => emit(MatchError(failure.errorMessage)),
      (teamPair) {
        // 2. Si es exitoso, ahora hay que actualizar el Match en el backend
        // **PENDIENTE:** Llamar a un Use Case de actualización aquí: 
        // sl<UpdateMatchWithTeams>().call(params...);

        emit(TeamsGeneratedSuccess(teamPair: teamPair)); 
      },
    );
  }
}