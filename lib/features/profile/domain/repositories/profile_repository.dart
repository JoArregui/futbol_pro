import '../entities/user_profile.dart';

abstract class ProfileRepository {
  // Obtiene el perfil del usuario actual por su UID.
  Future<UserProfile> getUserProfile(String uid);

  // Actualiza los campos editables del perfil.
  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? name,
    String? bio,
    String? avatarUrl,
  });

  // Opcional: Podríamos tener un stream para escuchar cambios en tiempo real, similar al chat.
  // Stream<UserProfile> streamUserProfile(String uid);
}