import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_profile_model.dart';
// Asegúrate de que esta ruta es correcta
import 'package:futbol_pro/core/errors/exceptions.dart';

import 'package:futbol_pro/core/consts.dart';

String get _kBaseUrl => '${AppConsts.effectiveBaseUrl}/users';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> fetchUserProfile(String uid);
  Future<void> createProfileInitial(UserProfileModel profile);
  Future<void> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client client;

  ProfileRemoteDataSourceImpl({required this.client});

  // ==================================================
  // OBTENER PERFIL (GET a la API)
  // ==================================================
  @override
  Future<UserProfileModel> fetchUserProfile(String uid) async {
    final url = Uri.parse('$_kBaseUrl/$uid/profile');

    try {
      final response =
          await client.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return UserProfileModel.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Perfil de usuario no encontrado.');
      } else {
        throw ServerException(
            message: 'Error al obtener el perfil: ${response.statusCode}');
      }
    } on NotFoundException {
      rethrow;
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }

  // ==================================================
  // CREAR PERFIL INICIAL (POST a la API)
  // ==================================================
  @override
  Future<void> createProfileInitial(UserProfileModel profile) async {
    final url = Uri.parse('$_kBaseUrl/${profile.uid}/profile');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toMap()),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ServerException(
            message: 'Error al crear perfil: ${response.statusCode}');
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al crear perfil: $e');
    }
  }

  // ==================================================
  // ACTUALIZAR PERFIL (PUT a la API)
  // ==================================================
  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = data['uid'] as String;
    final url = Uri.parse('$_kBaseUrl/$uid/profile');

    final updateData = Map<String, dynamic>.from(data)..remove('uid');

    try {
      final response = await client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode != 200) {
        throw ServerException(
            message: 'Error al actualizar perfil: ${response.statusCode}');
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e) {
      throw ServerException(
          message: 'Fallo de conexión al actualizar perfil: $e');
    }
  }
}
