import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart'; 
import '../models/match_model.dart';

// URL base de tu API (¡AJUSTA ESTO A TU ENTORNO!)
const String BASE_URL = 'https://tu-api-backend.com/api/v1';


// ==============================================================
// 1. CONTRATO (INTERFAZ ABSTRACTA)
// ==============================================================
abstract class MatchRemoteDataSource {
  Future<MatchModel> scheduleFriendlyMatch(
      {required DateTime time, required String fieldId});
      
  Future<List<MatchModel>> getUpcomingMatches();
  
  Future<MatchModel> addPlayerToMatch(
      {required String matchId, required String playerId});
}

// ==============================================================
// 2. IMPLEMENTACIÓN
// ==============================================================
class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final http.Client client;

  MatchRemoteDataSourceImpl({required this.client});

  // Método auxiliar para manejar los códigos de estado HTTP y lanzar excepciones
  void _handleStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
        throw UnauthorizedException();
      case 403:
        throw ForbiddenException();
      case 404:
        throw NotFoundException();
      case 409:
        throw ConflictException();
      // Otros códigos de error 4xx o 5xx se manejarán por defecto
      default:
        throw ServerException();
    }
  }

  @override
  Future<MatchModel> scheduleFriendlyMatch(
      {required DateTime time, required String fieldId}) async {
    final response = await client.post(
      Uri.parse('$BASE_URL/matches'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'time': time.toIso8601String(),
        'fieldId': fieldId,
      }),
    );

    if (response.statusCode == 201) { // 201 Created es común para POST exitoso
      return MatchModel.fromJson(json.decode(response.body));
    } else {
      _handleStatusCode(response.statusCode);
      throw ServerException(); 
    }
  }

  @override
  Future<List<MatchModel>> getUpcomingMatches() async {
    final response = await client.get(
      Uri.parse('$BASE_URL/matches/upcoming'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => MatchModel.fromJson(json)).toList();
    } else {
      _handleStatusCode(response.statusCode);
      throw ServerException();
    }
  }

  @override
  Future<MatchModel> addPlayerToMatch(
      {required String matchId, required String playerId}) async {
    final response = await client.post(
      Uri.parse('$BASE_URL/matches/$matchId/join'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'playerId': playerId
      }),
    );

    if (response.statusCode == 200) {
      // El backend devuelve el objeto Match actualizado
      return MatchModel.fromJson(json.decode(response.body));
    } else {
      // Maneja específicamente el 409 (Conflicto) y otros errores
      _handleStatusCode(response.statusCode);
      throw ServerException();
    }
  }
}