import 'package:equatable/equatable.dart';

// Este modelo representa la estructura de datos que se envía/recibe del backend para un equipo.
class TeamModel extends Equatable {
  final String name;
  final List<String> playerIds; // Lista de IDs (Strings)
  final double combinedRating;

  const TeamModel({
    required this.name,
    required this.playerIds,
    required this.combinedRating,
  });

  // Constructor fromJson (necesario si alguna vez lo lees directamente)
  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      name: json['name'] as String,
      playerIds: List<String>.from(json['playerIds'] as List),
      combinedRating: (json['combinedRating'] as num).toDouble(),
    );
  }

  // Método toJson (CRUCIAL para enviar el equipo en updateMatchTeams)
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