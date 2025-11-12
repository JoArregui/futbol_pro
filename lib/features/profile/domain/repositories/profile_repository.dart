import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile(String uid);

  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? name,
    String? bio,
    String? avatarUrl,
  });
}
