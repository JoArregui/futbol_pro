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