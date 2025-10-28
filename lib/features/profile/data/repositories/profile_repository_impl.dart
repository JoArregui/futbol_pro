import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    try {
      // Llama al DataSource para obtener el Model
      final profileModel = await remoteDataSource.fetchUserProfile(uid);
      
      // El Model es también la Entity, así que lo retornamos directamente
      return profileModel;
      
    } catch (e) {
      // Re-lanza la excepción o la envuelve en una excepción de dominio si es necesario
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
      'uid': uid, // Se necesita para el Datasource
      if (nickname != null) 'nickname': nickname,
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };

    try {
      // Llama al DataSource para actualizar la data
      await remoteDataSource.updateProfile(updateData);
    } catch (e) {
      throw Exception('Fallo en el Repositorio al actualizar perfil: $e');
    }
  }
}