import 'package:equatable/equatable.dart';

class Standing extends Equatable {
  final String teamName;
  final String teamId;
  final int points;
  final int gamesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  const Standing({
    required this.teamName,
    required this.teamId,
    required this.points,
    required this.gamesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
  });

  // 🚀 CORRECCIÓN CLAVE: Uso del operador ?? 0 para manejar nulos
  // Esto asegura que si 'points' es null, se usa 0 en su lugar, evitando el error.
  factory Standing.fromJson(Map<String, dynamic> json) {
    return Standing(
      teamName: json['teamName'] as String? ?? 'Equipo Desconocido',
      teamId: json['teamId'] as String? ?? 'ID Desconocido',
      points: json['points'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      goalDifference: json['goalDifference'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        teamName,
        teamId,
        points,
        gamesPlayed,
        wins,
        draws,
        losses,
        goalsFor,
        goalsAgainst,
        goalDifference,
      ];
}