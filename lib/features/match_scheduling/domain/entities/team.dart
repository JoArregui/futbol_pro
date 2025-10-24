import 'package:equatable/equatable.dart';
import 'player.dart'; // Importa la entidad Player ya definida

class Team extends Equatable {
  final String name; // Ejemplo: 'Equipo A', 'Equipo B'
  final List<Player> players;
  final double combinedRating; // Suma de los ratings de los jugadores

  const Team({
    required this.name,
    required this.players,
    required this.combinedRating,
  });

  @override
  List<Object> get props => [name, players, combinedRating];
}