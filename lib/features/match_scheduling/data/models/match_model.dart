import '../../domain/entities/match.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/entities/team.dart';

class MatchModel extends Match {
  final Team? teamA;
  final Team? teamB;

  /// Detalle enriquecido (solo en GET /matches/:id): marcador, MVP,
  /// resultado propuesto/confirmado y participantes con reputación.
  final int? golesA;
  final int? golesB;
  final String? mvpId;
  final MatchResult? result;
  final List<MatchParticipant> participants;

  /// Coste total del partido para dividir entre participantes.
  final double? costeTotal;

  const MatchModel({
    required super.id,
    required super.title,
    required super.scheduledTime,
    required super.fieldId,
    required super.type,
    required super.playerIds,
    super.mode = MatchMode.openPlayers,
    super.needsReferee = false,
    super.description,
    super.organizerTeamName,
    super.opponentTeamName,
    super.maxPlayers,
    super.leagueId,
    this.teamA,
    this.teamB,
    this.golesA,
    this.golesB,
    this.mvpId,
    this.result,
    this.participants = const [],
    this.costeTotal,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    Team? parseTeam(Map<String, dynamic>? teamJson) {
      if (teamJson == null) return null;

      return Team.fromJson(teamJson);
    }

    final rawMode = (json['mode'] ?? json['modo'] ?? 'open').toString();
    final mode = rawMode == 'team' ? MatchMode.teamVsTeam : MatchMode.openPlayers;
    final typeStr = (json['type'] ?? json['tipo'] ?? 'friendly').toString();

    List<String> parsePlayers(dynamic raw) {
      if (raw == null) return const [];
      // Solo IDs escalares: la lista enriquecida de participantes (Map)
      // se procesa aparte en parseParticipants.
      if (raw is List) {
        return raw
            .where((e) => e is String || e is num)
            .map((e) => e.toString())
            .toList();
      }
      return const [];
    }

    List<MatchParticipant> parseParticipants(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) =>
              MatchParticipant.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final participants = parseParticipants(json['participants']);
    final playerIds = parsePlayers(json['playerIds'] ?? json['participants']);
    final mergedIds = {
      ...playerIds,
      ...participants.map((p) => p.id),
    }.toList();

    MatchResult? result;
    final rawResult = json['result'];
    if (rawResult is Map) {
      result =
          MatchResult.fromJson(Map<String, dynamic>.from(rawResult));
    }

    return MatchModel(
      id: (json['id'] ?? json['id_partido'] ?? '').toString(),
      title: (json['title'] ??
              json['titulo'] ??
              json['organizerTeam'] ??
              'Amistoso')
          .toString(),
      scheduledTime: DateTime.tryParse(
            (json['scheduledTime'] ?? json['time'] ?? json['hora_inicio'])
                    ?.toString() ??
                '',
          ) ??
          DateTime.now(),
      fieldId: (json['fieldId'] ?? json['id_campo_fk'] ?? '').toString(),
      type: typeStr == 'league' ? MatchType.league : MatchType.friendly,
      playerIds: mergedIds,
      mode: mode,
      needsReferee: json['needsReferee'] == true || json['needsReferee'] == 1,
      description: json['description']?.toString(),
      organizerTeamName: json['organizerTeam']?.toString(),
      opponentTeamName: json['opponentTeam']?.toString(),
      maxPlayers: (json['maxPlayers'] as num?)?.toInt(),
      leagueId: json['leagueId']?.toString(),
      teamA: parseTeam(json['teamA'] as Map<String, dynamic>?),
      teamB: parseTeam(json['teamB'] as Map<String, dynamic>?),
      golesA: (json['golesA'] as num?)?.toInt(),
      golesB: (json['golesB'] as num?)?.toInt(),
      mvpId: json['mvpId']?.toString(),
      result: result,
      participants: participants,
      costeTotal: (json['costeTotal'] ?? json['totalCost'] as num?)
          ?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scheduledTime': scheduledTime.toIso8601String(),
      'fieldId': fieldId,
      'type': type == MatchType.league ? 'league' : 'friendly',
      'playerIds': playerIds,
      'mode': mode == MatchMode.teamVsTeam ? 'team' : 'open',
      'needsReferee': needsReferee,
      if (description != null) 'description': description,
      if (organizerTeamName != null) 'organizerTeam': organizerTeamName,
      if (opponentTeamName != null) 'opponentTeam': opponentTeamName,
      if (maxPlayers != null) 'maxPlayers': maxPlayers,
      if (leagueId != null) 'leagueId': leagueId,
      'teamA': teamA?.toJson(),
      'teamB': teamB?.toJson(),
    };
  }
}
