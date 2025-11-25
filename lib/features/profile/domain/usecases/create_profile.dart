import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class CreateProfile {
  final ProfileRepository repository;

  const CreateProfile(this.repository);

  Future<UserProfile> call({
    required String uid,
    required String email,
    required String nickname,
  }) {
    return repository.createProfile(uid, email, nickname);
  }
}