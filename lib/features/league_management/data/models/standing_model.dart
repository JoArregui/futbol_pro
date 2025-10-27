/*
import '../../domain/entities/standing.dart';

class StandingModel extends Standing {
  const StandingModel({
    required super.teamName,
    required super.teamId,
    required super.points,
    required super.gamesPlayed,
    required super.wins,
    required super.draws,
    required super.losses,
    required super.goalsFor,
    required super.goalsAgainst,
    required super.goalDifference,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    return StandingModel(
      teamName: json['teamName'],
      teamId: json['teamId'],
      points: json['points'],
      gamesPlayed: json['gamesPlayed'],
      wins: json['wins'],
      draws: json['draws'],
      losses: json['losses'],
      goalsFor: json['goalsFor'],
      goalsAgainst: json['goalsAgainst'],
      goalDifference: json['goalsFor'] - json['goalsAgainst'], 
    );
  }
}
*/

import '../../domain/entities/standing.dart';

class StandingModel extends Standing {
  const StandingModel({
    required super.teamName,
    required super.teamId,
    required super.points,
    required super.gamesPlayed,
    required super.wins,
    required super.draws,
    required super.losses,
    required super.goalsFor,
    required super.goalsAgainst,
    required super.goalDifference,
  });

  factory StandingModel.fromJson(Map<String, dynamic> json) {
    // Es buena práctica asegurar que todos los campos numéricos se castean a int.
    final goalsFor = json['goalsFor'] as int;
    final goalsAgainst = json['goalsAgainst'] as int;
    
    return StandingModel(
      teamName: json['teamName'] as String,
      teamId: json['teamId'] as String,
      points: json['points'] as int,
      gamesPlayed: json['gamesPlayed'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      // Se puede calcular la diferencia de goles aquí
      goalDifference: goalsFor - goalsAgainst, 
    );
  }
}
