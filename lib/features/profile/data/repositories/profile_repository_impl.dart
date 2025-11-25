import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart'; // Importar el modelo para crear instancia

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  // Implementación de la creación
  @override
  Future<UserProfile> createProfile(
      String uid, String email, String nickname) async {
    try {
      final newProfile =
          UserProfileModel.initial(uid, email, nickname);
      await remoteDataSource.createProfileInitial(newProfile);
      return newProfile;
    } catch (e) {
      throw Exception('Fallo en el Repositorio al crear perfil: $e');
    }
  }

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    try {
      final profileModel = await remoteDataSource.fetchUserProfile(uid);
      return profileModel;
    } catch (e) {
      throw Exception('Fallo en el Repositorio al obtener perfil: $e');
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final updateData = {
      'uid': uid,
      if (nickname != null) 'nickname': nickname,
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };

    try {
      await remoteDataSource.updateProfile(updateData);
    } catch (e) {
      throw Exception('Fallo en el Repositorio al actualizar perfil: $e');
    }
  }
}