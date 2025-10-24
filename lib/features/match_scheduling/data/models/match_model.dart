import '../../domain/entities/match.dart';

class MatchModel extends Match {
  const MatchModel({
    required super.id,
    required super.title,
    required super.scheduledTime,
    required super.fieldId,
    required super.type,
    required super.playerIds,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      fieldId: json['fieldId'] as String,
      type: (json['type'] as String) == 'league' ? MatchType.league : MatchType.friendly,
      playerIds: List<String>.from(json['playerIds'] as List),
    );
  }

  // Método para convertir a JSON para enviar a la API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scheduledTime': scheduledTime.toIso8601String(),
      'fieldId': fieldId,
      'type': type == MatchType.league ? 'league' : 'friendly',
      'playerIds': playerIds,
    };
  }
}