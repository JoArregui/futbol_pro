import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> fetchUserProfile(String uid);
  // 🚀 NUEVO: Crear un perfil la primera vez.
  Future<void> createProfileInitial(UserProfileModel profile);
  Future<void> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  ProfileRemoteDataSourceImpl({required this.firestore});

  static const String usersCollection = 'users';

  @override
  Future<UserProfileModel> fetchUserProfile(String uid) async {
    try {
      final docSnapshot =
          await firestore.collection(usersCollection).doc(uid).get();

      if (!docSnapshot.exists) {
        // En lugar de lanzar una excepción, podrías crear el perfil inicial aquí
        // o dejar que el BLoC lo maneje. Por ahora, lanzamos para que el BLoC lo detecte.
        throw Exception('Usuario no encontrado en la base de datos.');
      }

      return UserProfileModel.fromSnapshot(docSnapshot);
    } catch (e) {
      // Manejo de errores de Firestore (permisos, red)
      throw Exception('Error al obtener el perfil del usuario: $e');
    }
  }

  // 🚀 Implementación de la creación inicial
  @override
  Future<void> createProfileInitial(UserProfileModel profile) async {
    try {
      // Usar set(data) para crear el documento con el UID como ID.
      await firestore
          .collection(usersCollection)
          .doc(profile.uid)
          .set(profile.toMap());
    } catch (e) {
      throw Exception('Error al crear el perfil inicial: $e');
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final uid = data['uid'] as String;

      // Usar .remove('uid') en una copia
      final updateData = Map<String, dynamic>.from(data)..remove('uid');

      // Si el campo es nulo, se puede optar por no enviarlo a Firestore.
      await firestore.collection(usersCollection).doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Error al actualizar el perfil: $e');
    }
  }
}