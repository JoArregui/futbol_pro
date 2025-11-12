import 'package:equatable/equatable.dart';
import 'player.dart';
import '../../data/models/team_model.dart';

class Team extends Equatable {
  final String name;
  final List<Player> players;
  final double combinedRating;

  const Team({
    required this.name,
    required this.players,
    required this.combinedRating,
  });

  TeamModel toModel() {
    return TeamModel(
      name: name,
      playerIds: players.map((p) => p.id).toList(),
      combinedRating: combinedRating,
    );
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    final List<Player> playerList = (json['players'] as List<dynamic>?)
            ?.map((playerJson) =>
                Player.fromJson(playerJson as Map<String, dynamic>))
            .toList() ??
        [];

    return Team(
      name: json['name'] as String,
      players: playerList,
      combinedRating: (json['combinedRating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'playerIds': players.map((p) => p.id).toList(),
      'combinedRating': combinedRating,
    };
  }

  @override
  List<Object> get props => [name, players, combinedRating];
}
