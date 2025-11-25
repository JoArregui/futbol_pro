import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.email,
    required super.nickname,
    super.name,
    super.avatarUrl,
    super.bio,
    required super.gamesPlayed,
    required super.wins,
    required super.rating,
    required super.createdAt,
  });

  // 🚀 NUEVA FUNCIÓN: Deserialización desde JSON (API REST)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Usamos el UID proporcionado en el JSON
    final uid = json['uid'] as String;
    
    // Convertir el string de fecha (ISO 8601) a DateTime
    final createdAtString = json['createdAt'] as String? ?? DateTime.now().toIso8601String();

    return UserProfileModel(
      uid: uid,
      email: json['email'] as String? ?? 'correo_no_disponible@app.com',
      nickname: json['nickname'] as String? ?? 'NuevoJugador',
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      // Manejo seguro de valores numéricos desde JSON (num? -> int/double)
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 1000.0,
      createdAt: DateTime.parse(createdAtString),
    );
  }

  // Genera un perfil inicial para un nuevo registro.
  factory UserProfileModel.initial(String uid, String email, String nickname) {
    return UserProfileModel(
      uid: uid,
      email: email,
      nickname: nickname,
      gamesPlayed: 0,
      wins: 0,
      rating: 1000.0, // Rating inicial común
      createdAt: DateTime.now(),
    );
  }

  // Conversión a Map para serialización a JSON (para POST/PUT)
  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // Incluir UID para las rutas de la API
      'email': email,
      'nickname': nickname,
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'rating': rating,
      // Usar ISO 8601 String para API REST
      'createdAt': createdAt.toIso8601String(), 
    };
  }
}