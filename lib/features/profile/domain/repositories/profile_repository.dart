import '../entities/user_profile.dart';

abstract class ProfileRepository {
  // 🚀 Nuevo método abstracto
  Future<UserProfile> createProfile(String uid, String email, String nickname);

  Future<UserProfile> getUserProfile(String uid);

  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? name,
    String? bio,
    String? avatarUrl,
    String? position,
    String? foot,
    bool? available,
  });
}
