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
    super.position,
    super.foot,
    super.available = true,
  });

  // 🚀 NUEVA FUNCIÓN: Deserialización desde JSON (API REST)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Usamos el UID proporcionado en el JSON
    final uid = (json['uid'] ?? json['id'] ?? '').toString();

    // Convertir el string de fecha (ISO 8601) a DateTime
    final createdAtString =
        (json['createdAt'] ?? json['fecha_creacion'])?.toString() ??
        DateTime.now().toIso8601String();

    return UserProfileModel(
      uid: uid,
      email: (json['email'] ?? 'correo_no_disponible@app.com').toString(),
      nickname: (json['nickname'] ?? json['apodo'] ?? 'NuevoJugador')
          .toString(),
      name: (json['name'] ?? json['nombre'])?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['url_avatar'])?.toString(),
      bio: json['bio']?.toString(),
      // Manejo seguro de valores numéricos desde JSON (num? -> int/double)
      gamesPlayed:
          (json['gamesPlayed'] ?? json['partidos_jugados'] as num?) is num
          ? ((json['gamesPlayed'] ?? json['partidos_jugados']) as num).toInt()
          : 0,
      wins: (json['wins'] ?? json['victorias'] as num?) is num
          ? ((json['wins'] ?? json['victorias']) as num).toInt()
          : 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 1000.0,
      createdAt: DateTime.tryParse(createdAtString) ?? DateTime.now(),
      position: (json['position'] ?? json['posicion'])?.toString(),
      foot: (json['foot'] ?? json['pierna'])?.toString(),
      available: _parseAvailable(json),
    );
  }

  static bool _parseAvailable(Map<String, dynamic> json) {
    final v = json.containsKey('available')
        ? json['available']
        : json['disponible'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v != '0' && v.toLowerCase() != 'false';
    return true;
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
      'position': position,
      'foot': foot,
      'available': available,
    };
  }
}
