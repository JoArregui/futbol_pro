import '../../domain/entities/tournament.dart';

class TournamentModel extends Tournament {
  const TournamentModel({
    required super.id,
    required super.name,
    required super.description,
    required super.startDate,
    required super.maxTeams,
    required super.registeredTeams,
    required super.status,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Torneo').toString(),
      description: (json['description'] ?? '').toString(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      maxTeams: (json['maxTeams'] as num?)?.toInt() ?? 16,
      registeredTeams: (json['registeredTeams'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'open').toString(),
    );
  }
}
