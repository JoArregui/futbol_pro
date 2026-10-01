import 'package:equatable/equatable.dart';

class ActaScorer extends Equatable {
  final String playerId;
  final String name;
  final int goles;
  const ActaScorer(
      {required this.playerId, required this.name, required this.goles});
  @override
  List<Object> get props => [playerId, name, goles];
}

class ActaParticipant extends Equatable {
  final String id;
  final String name;
  final int noShows;
  const ActaParticipant(
      {required this.id, required this.name, required this.noShows});
  @override
  List<Object> get props => [id, name, noShows];
}

/// Acta del partido (server/routes/matches.js GET /:id/acta).
class MatchActa extends Equatable {
  final String matchId;
  final String field;
  final String time;
  final String status;
  final String type;
  final int? golesA;
  final int? golesB;
  final String estado; // validado | propuesta | sin_registrar...
  final String? mvp;
  final List<ActaScorer> scorers;
  final List<ActaParticipant> participants;

  const MatchActa({
    required this.matchId,
    required this.field,
    required this.time,
    required this.status,
    required this.type,
    this.golesA,
    this.golesB,
    required this.estado,
    this.mvp,
    this.scorers = const [],
    this.participants = const [],
  });

  bool get isValidated => estado == 'confirmado' || estado == 'validado';

  factory MatchActa.fromJson(Map<String, dynamic> j) => MatchActa(
        matchId: (j['matchId'] ?? '').toString(),
        field: (j['field'] ?? '').toString(),
        time: (j['time'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        golesA: (j['golesA'] as num?)?.toInt(),
        golesB: (j['golesB'] as num?)?.toInt(),
        estado: (j['estado'] ?? '').toString(),
        mvp: j['mvp']?.toString(),
        scorers: ((j['scorers'] as List?) ?? [])
            .map((e) => ActaScorer(
                  playerId: (e['playerId'] ?? '').toString(),
                  name: (e['name'] ?? '').toString(),
                  goles: (e['goles'] as num?)?.toInt() ?? 0,
                ))
            .toList(),
        participants: ((j['participants'] as List?) ?? [])
            .map((e) => ActaParticipant(
                  id: (e['id'] ?? '').toString(),
                  name: (e['name'] ?? '').toString(),
                  noShows: (e['noShows'] as num?)?.toInt() ?? 0,
                ))
            .toList(),
      );

  @override
  List<Object?> get props => [
        matchId,
        field,
        time,
        status,
        type,
        golesA,
        golesB,
        estado,
        mvp,
        scorers,
        participants,
      ];
}
