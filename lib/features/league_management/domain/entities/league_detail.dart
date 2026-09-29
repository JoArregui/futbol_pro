import 'package:equatable/equatable.dart';
import 'standing.dart';

/// Equipo inscrito en una liga, con su plantilla.
class LeagueTeam extends Equatable {
  final String id;
  final String nombre;
  final String capitanId;
  final List<String> plantilla;

  const LeagueTeam({
    required this.id,
    required this.nombre,
    required this.capitanId,
    this.plantilla = const [],
  });

  factory LeagueTeam.fromJson(Map<String, dynamic> json) => LeagueTeam(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        capitanId: (json['capitanId'] ?? '').toString(),
        plantilla: (json['plantilla'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  List<Object> get props => [id, nombre, capitanId, plantilla];
}

/// Un cruce del fixture: jornada, equipos, partido asociado y marcador.
class FixtureEntry extends Equatable {
  final int jornada;
  final String equipoAId;
  final String equipoANombre;
  final String equipoBId;
  final String equipoBNombre;
  final String? matchId;
  final String? status;
  final int? golesA;
  final int? golesB;

  const FixtureEntry({
    required this.jornada,
    required this.equipoAId,
    required this.equipoANombre,
    required this.equipoBId,
    required this.equipoBNombre,
    this.matchId,
    this.status,
    this.golesA,
    this.golesB,
  });

  bool get jugado => golesA != null && golesB != null;

  factory FixtureEntry.fromJson(Map<String, dynamic> json) => FixtureEntry(
        jornada: (json['jornada'] as num?)?.toInt() ?? 0,
        equipoAId: (json['equipoA']?['id'] ?? '').toString(),
        equipoANombre: (json['equipoA']?['nombre'] ?? '').toString(),
        equipoBId: (json['equipoB']?['id'] ?? '').toString(),
        equipoBNombre: (json['equipoB']?['nombre'] ?? '').toString(),
        matchId: json['matchId']?.toString(),
        status: json['status']?.toString(),
        golesA: (json['golesA'] as num?)?.toInt(),
        golesB: (json['golesB'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [
        jornada,
        equipoAId,
        equipoANombre,
        equipoBId,
        equipoBNombre,
        matchId,
        status,
        golesA,
        golesB,
      ];
}

/// Fila de la tabla de goleadores de la liga.
class ScorerRow extends Equatable {
  final String playerId;
  final String name;
  final int goles;

  const ScorerRow(
      {required this.playerId, required this.name, required this.goles});

  factory ScorerRow.fromJson(Map<String, dynamic> json) => ScorerRow(
        playerId: (json['playerId'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        goles: (json['goles'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object> get props => [playerId, name, goles];
}

/// Agregado del detalle de liga (carga paralela en el repositorio).
class LeagueDetail extends Equatable {
  final List<LeagueTeam> teams;
  final List<FixtureEntry> fixture;
  final List<Standing> standings;
  final List<ScorerRow> scorers;

  const LeagueDetail({
    this.teams = const [],
    this.fixture = const [],
    this.standings = const [],
    this.scorers = const [],
  });

  @override
  List<Object> get props => [teams, fixture, standings, scorers];
}
