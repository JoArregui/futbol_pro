import 'package:equatable/equatable.dart';
import 'player.dart'; // Importa la entidad Player ya definida
import '../../data/models/team_model.dart'; // 🆕 Necesitas importar TeamModel

class Team extends Equatable {
  final String name; // Ejemplo: 'Equipo A', 'Equipo B'
  final List<Player> players;
  final double combinedRating; // Suma de los ratings de los jugadores

  const Team({
    required this.name,
    required this.players,
    required this.combinedRating,
  });

  // ========================================================
  // 🆕 MÉTODO TO MODEL (CONVERSIÓN DE DOMINIO A DATOS)
  // Requerido por el repositorio para enviar datos al DataSource.
  // ========================================================
  TeamModel toModel() {
    return TeamModel(
      name: name,
      // Mapea la lista de entidades Player a una lista de String (solo IDs)
      playerIds: players.map((p) => p.id).toList(), 
      combinedRating: combinedRating,
    );
  }
  
  // ========================================================
  // MÉTODO FROM JSON (DESERIALIZACIÓN)
  // ========================================================
  factory Team.fromJson(Map<String, dynamic> json) {
    // ... lógica fromJson existente ...
    final List<Player> playerList = (json['players'] as List<dynamic>?)
        ?.map((playerJson) => Player.fromJson(playerJson as Map<String, dynamic>))
        .toList() ?? [];

    return Team(
      name: json['name'] as String,
      players: playerList,
      combinedRating: (json['combinedRating'] as num).toDouble(),
    );
  }

  // ========================================================
  // MÉTODO TO JSON (SERIALIZACIÓN)
  // ========================================================
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // Al enviar al backend, generalmente solo enviamos los IDs
      'playerIds': players.map((p) => p.id).toList(), 
      'combinedRating': combinedRating,
    };
  }

  @override
  List<Object> get props => [name, players, combinedRating];
}