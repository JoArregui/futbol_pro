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

  @override
  List<Object> get props => [id, name, nickname, profileImageUrl, rating];
}