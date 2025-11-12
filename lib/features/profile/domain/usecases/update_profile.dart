import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  const UpdateProfile(this.repository);

  Future<void> call({
    required String uid,
    String? nickname,
    String? name,
    String? bio,
    String? avatarUrl,
  }) {
    if (nickname != null && nickname.isEmpty) {
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
