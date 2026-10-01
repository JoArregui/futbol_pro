import 'package:equatable/equatable.dart';

class Match extends Equatable {
  final String id;
  final String title;
  final DateTime scheduledTime;
  final String fieldId;
  final MatchType type;
  final List<String> playerIds;
  final MatchMode mode;
  final bool needsReferee;
  final String? description;
  final String? organizerTeamName;
  final String? opponentTeamName;
  final int? maxPlayers;
  final String? leagueId;

  const Match({
    required this.id,
    required this.title,
    required this.scheduledTime,
    required this.fieldId,
    required this.type,
    required this.playerIds,
    this.mode = MatchMode.openPlayers,
    this.needsReferee = false,
    this.description,
    this.organizerTeamName,
    this.opponentTeamName,
    this.maxPlayers,
    this.leagueId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        scheduledTime,
        fieldId,
        type,
        playerIds,
        mode,
        needsReferee,
        description,
        organizerTeamName,
        opponentTeamName,
        maxPlayers,
        leagueId,
      ];
}

enum MatchType { league, friendly }

/// Modo de creación del amistoso:
/// - openPlayers: jugadores sueltos se apuntan hasta completar.
/// - teamVsTeam: equipo completo reta a otro (o queda abierto a retos).
enum MatchMode { openPlayers, teamVsTeam }
