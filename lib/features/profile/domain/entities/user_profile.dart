import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String email;
  final String nickname;

  // Campos opcionales
  final String? name;
  final String? avatarUrl;
  final String? bio;

  // Métricas del juego
  final int gamesPlayed;
  final int wins;
  final double rating;

  // Ficha deportiva (opcional, editable en Perfil)
  final String? position; // Portero | Defensa | Medio | Delantero
  final String? foot; // diestro | zurdo | ambidiestro
  final bool available;

  // Metadatos
  final DateTime createdAt; // Fecha de creación del perfil

  const UserProfile({
    required this.uid,
    required this.email,
    required this.nickname,
    this.name,
    this.avatarUrl,
    this.bio,
    required this.gamesPlayed,
    required this.wins,
    required this.rating,
    required this.createdAt,
    this.position,
    this.foot,
    this.available = true,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? name,
    String? avatarUrl,
    String? bio,
    int? gamesPlayed,
    int? wins,
    double? rating,
    DateTime? createdAt,
    String? Function()? position,
    String? Function()? foot,
    bool? available,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      position: position != null ? position() : this.position,
      foot: foot != null ? foot() : this.foot,
      available: available ?? this.available,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    nickname,
    name,
    avatarUrl,
    bio,
    gamesPlayed,
    wins,
    rating,
    createdAt,
    position,
    foot,
    available,
  ];
}
