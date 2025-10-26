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

  @override
  List<Object> get props => [
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