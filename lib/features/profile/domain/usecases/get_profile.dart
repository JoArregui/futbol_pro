import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;

  // ✅ Simplificado: El constructor ahora solo requiere el repositorio.
  const GetProfile(this.repository);

  // El método call permite llamar a la instancia como si fuera una función
  Future<UserProfile> call(String uid) {
    return repository.getUserProfile(uid);
  }
}
