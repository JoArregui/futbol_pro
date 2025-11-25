import 'package:cloud_firestore/cloud_firestore.dart';
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

  // 🚀 CORRECCIÓN: Manejo robusto de nulos para campos numéricos y de texto.
  factory UserProfileModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('El documento de perfil está vacío.');
    }

    // Inicializa el timestamp con una fecha actual si falta (idealmente no debería faltar)
    final timestamp = data['createdAt'] as Timestamp? ?? Timestamp.now();

    return UserProfileModel(
      uid: doc.id,
      email: data['email'] as String? ?? 'correo_no_disponible@app.com',
      nickname: data['nickname'] as String? ?? 'NuevoJugador',
      name: data['name'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      // 🚨 Los valores numéricos deben usar ?? 0 (o 0.0) para evitar errores 'Null is not a subtype of int'
      gamesPlayed: (data['gamesPlayed'] as num?)?.toInt() ?? 0,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: timestamp.toDate(),
    );
  }

  // 🚀 NUEVA FUNCIÓN: Genera un perfil inicial para un nuevo registro.
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

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nickname': nickname,
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}