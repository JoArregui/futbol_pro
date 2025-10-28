import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  // ✅ Simplificado: El constructor ahora solo requiere el repositorio.
  const UpdateProfile(this.repository);

  Future<void> call({
    required String uid,
    String? nickname,
    String? name,
    String? bio,
    String? avatarUrl,
  }) {
    // Aquí puedes añadir lógica de dominio, como validación básica de datos
    if (nickname != null && nickname.isEmpty) {
      // ⚠️ En un entorno BLoC, es mejor devolver un Failure (Either) 
      // en lugar de lanzar una excepción para un manejo de errores más limpio.
      throw Exception('El nickname no puede estar vacío.'); 
    }
    
    return repository.updateProfile(
      uid: uid,
      nickname: nickname,
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }
}
