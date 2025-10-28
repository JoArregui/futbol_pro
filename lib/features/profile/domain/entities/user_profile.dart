// Archivo: lib/domain/entities/user_profile.dart

import 'package:equatable/equatable.dart';

// Entidad que representa la información de perfil de un usuario.
class UserProfile extends Equatable {
  final String uid; // Identificador único del usuario (obligatorio)
  final String email; // Correo electrónico (obligatorio)
  final String nickname; // Nombre de usuario visible (obligatorio)
  
  // Campos opcionales
  final String? name; // Nombre real del usuario
  final String? avatarUrl; // URL de la imagen de perfil
  final String? bio; // Breve biografía o descripción

  // Métricas del juego
  final int gamesPlayed; // Número de partidas jugadas
  final int wins; // Número de victorias
  final double rating; // Puntuación de habilidad (rating)
  
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
  });

  // Método para crear una copia de la entidad modificando campos específicos (Inmutabilidad)
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
      ];
}