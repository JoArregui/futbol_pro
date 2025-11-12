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