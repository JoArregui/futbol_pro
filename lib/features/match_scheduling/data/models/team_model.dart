import 'package:equatable/equatable.dart';

class TeamModel extends Equatable {
  final String name;
  final List<String> playerIds;
  final double combinedRating;

  const TeamModel({
    required this.name,
    required this.playerIds,
    required this.combinedRating,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      name: json['name'] as String,
      playerIds: List<String>.from(json['playerIds'] as List),
      combinedRating: (json['combinedRating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'playerIds': playerIds,
      'combinedRating': combinedRating,
    };
  }

  @override
  List<Object> get props => [name, playerIds, combinedRating];
}
