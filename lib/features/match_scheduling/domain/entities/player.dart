import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final String nickname;
  final String profileImageUrl;
  final double rating; // Para el sistema de equilibrio de equipos (opcional, pero útil)

  const Player({
    required this.id,
    required this.name,
    required this.nickname,
    required this.profileImageUrl,
    this.rating = 0.0,
  });

  // ========================================================
  // 🆕 MÉTODO FROM JSON (DESERIALIZACIÓN)
  // Requerido por Team.fromJson para construir la lista de jugadores.
  // ========================================================
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      // Usamos `num` y luego `toDouble()` para manejar enteros o doubles recibidos del JSON.
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0, 
    );
  }

  // ========================================================
  // 🆕 MÉTODO TO JSON (SERIALIZACIÓN)
  // Requerido si necesitas enviar datos detallados del jugador a la API.
  // ========================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
    };
  }

  @override
  List<Object> get props => [id, name, nickname, profileImageUrl, rating];
}