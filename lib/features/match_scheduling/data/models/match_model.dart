import '../../domain/entities/match.dart';
import '../../domain/entities/team.dart';

class MatchModel extends Match {
  final Team? teamA;
  final Team? teamB;

  const MatchModel({
    required super.id,
    required super.title,
    required super.scheduledTime,
    required super.fieldId,
    required super.type,
    required super.playerIds,
    this.teamA,
    this.teamB,
  });

  // =========================================================
  // CONSTRUCTOR FROM JSON (PARA RECIBIR DATOS DEL BACKEND)
  // =========================================================
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    Team? parseTeam(Map<String, dynamic>? teamJson) {
      if (teamJson == null) return null;

      return Team.fromJson(teamJson);
    }

    return MatchModel(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      fieldId: json['fieldId'] as String,
      type: (json['type'] as String) == 'league'
          ? MatchType.league
          : MatchType.friendly,
      playerIds: List<String>.from(json['playerIds'] as List),
      teamA: parseTeam(json['teamA'] as Map<String, dynamic>?),
      teamB: parseTeam(json['teamB'] as Map<String, dynamic>?),
    );
  }

  // =========================================================
  // MÉTODO TO JSON (PARA ENVIAR DATOS AL BACKEND)
  // =========================================================
  // Se eliminó la anotación @override porque Match no define este método.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scheduledTime': scheduledTime.toIso8601String(),
      'fieldId': fieldId,
      'type': type == MatchType.league ? 'league' : 'friendly',
      'playerIds': playerIds,
      'teamA': teamA?.toJson(),
      'teamB': teamB?.toJson(),
    };
  }
}
