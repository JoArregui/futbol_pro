import 'package:equatable/equatable.dart';

/// Participante enriquecido (viene de GET /matches/:id).
class MatchParticipant extends Equatable {
  final String id;
  final String name;
  final String nickname;
  final String? profileImageUrl;
  final int played;
  final int wins;
  final int mvpCount;
  final int noShows;

  const MatchParticipant({
    required this.id,
    required this.name,
    required this.nickname,
    this.profileImageUrl,
    this.played = 0,
    this.wins = 0,
    this.mvpCount = 0,
    this.noShows = 0,
  });

  factory MatchParticipant.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    return MatchParticipant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      played: asInt(json['played']),
      wins: asInt(json['wins']),
      mvpCount: asInt(json['mvpCount']),
      noShows: asInt(json['noShows']),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, nickname, profileImageUrl, played, wins, mvpCount, noShows];
}

/// Goleador individual dentro de una propuesta.
class ScorerEntry extends Equatable {
  final String playerId;
  final int goles;

  const ScorerEntry({required this.playerId, required this.goles});

  Map<String, dynamic> toJson() => {'playerId': playerId, 'goles': goles};

  factory ScorerEntry.fromJson(Map<String, dynamic> json) => ScorerEntry(
        playerId: (json['playerId'] ?? '').toString(),
        goles: (json['goles'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object> get props => [playerId, goles];
}

/// Resultado propuesto o confirmado de un partido.
class MatchResult extends Equatable {
  final String matchId;
  final int golesA;
  final int golesB;
  final String ganador; // 'A' | 'B' | 'empate'
  final List<ScorerEntry> goleadores;
  final List<String> teamAIds;
  final List<String> teamBIds;
  final String? mvpId;
  final String propuestoPor;
  final String estado; // 'propuesta' | 'confirmado'
  final String? confirmedAt;

  const MatchResult({
    required this.matchId,
    required this.golesA,
    required this.golesB,
    this.ganador = 'empate',
    this.goleadores = const [],
    this.teamAIds = const [],
    this.teamBIds = const [],
    this.mvpId,
    required this.propuestoPor,
    required this.estado,
    this.confirmedAt,
  });

  bool get isConfirmed => estado == 'confirmado';

  String scoreLine() => '$golesA - $golesB';

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    List<ScorerEntry> parseScorers(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) =>
              ScorerEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<String> parseIds(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).toList();
    }

    return MatchResult(
      matchId: (json['matchId'] ?? '').toString(),
      golesA: (json['golesA'] as num?)?.toInt() ?? 0,
      golesB: (json['golesB'] as num?)?.toInt() ?? 0,
      ganador: (json['ganador'] ?? 'empate').toString(),
      goleadores: parseScorers(json['goleadores']),
      teamAIds: parseIds(json['teamAIds']),
      teamBIds: parseIds(json['teamBIds']),
      mvpId: json['mvpId']?.toString(),
      propuestoPor: (json['propuestoPor'] ?? '').toString(),
      estado: (json['estado'] ?? 'propuesta').toString(),
      confirmedAt: json['confirmedAt']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        matchId,
        golesA,
        golesB,
        ganador,
        goleadores,
        teamAIds,
        teamBIds,
        mvpId,
        propuestoPor,
        estado,
        confirmedAt,
      ];
}
