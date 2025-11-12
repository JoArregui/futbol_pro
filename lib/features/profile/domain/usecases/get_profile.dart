import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;

  const GetProfile(this.repository);

  Future<UserProfile> call(String uid) {
    return repository.getUserProfile(uid);
  }
}
