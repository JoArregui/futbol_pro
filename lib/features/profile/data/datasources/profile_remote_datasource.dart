import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart'; // Necesitará este Model

// Contrato de la fuente de datos para el perfil
abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> fetchUserProfile(String uid);
  Future<void> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  ProfileRemoteDataSourceImpl({required this.firestore});

  // Colección donde se almacenan los perfiles de usuario
  static const String usersCollection = 'users';

  @override
  Future<UserProfileModel> fetchUserProfile(String uid) async {
    try {
      final docSnapshot = await firestore.collection(usersCollection).doc(uid).get();

      if (!docSnapshot.exists) {
        throw Exception('Usuario no encontrado en la base de datos.');
      }

      // Convertir el documento de Firestore a nuestro Model
      return UserProfileModel.fromSnapshot(docSnapshot);
      
    } catch (e) {
      // Manejo de errores de red o base de datos
      throw Exception('Error al obtener el perfil del usuario: $e');
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final uid = data['uid'] as String;
      // Quitamos el 'uid' del mapa antes de actualizar el documento
      final updateData = Map<String, dynamic>.from(data)..remove('uid');
      
      await firestore.collection(usersCollection).doc(uid).update(updateData);
    } catch (e) {
      // Manejo de errores de red o permisos
      throw Exception('Error al actualizar el perfil: $e');
    }
  }
}