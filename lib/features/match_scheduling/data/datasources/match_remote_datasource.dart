import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart'; 
import '../models/match_model.dart';
import '../models/team_model.dart'; // ¡Ahora debe existir!

// URL base de tu API (¡Corregido a lowerCamelCase!)
const String baseUrl = 'https://tu-api-backend.com/api/v1';


// ==============================================================
// 1. CONTRATO (INTERFAZ ABSTRACTA) 
// ==============================================================
abstract class MatchRemoteDataSource {
  Future<MatchModel> scheduleFriendlyMatch(
      {required DateTime time, required String fieldId});
      
  Future<List<MatchModel>> getUpcomingMatches();
  
  Future<MatchModel> addPlayerToMatch(
      {required String matchId, required String playerId});

  Future<MatchModel> getMatchById(String matchId);

  Future<MatchModel> updateMatchTeams({
    required String matchId,
    required TeamModel teamA,
    required TeamModel teamB,
  });
}

// ==============================================================
// 2. IMPLEMENTACIÓN - Advertencias de estilo corregidas con 'const'
// ==============================================================
class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final http.Client client;

  MatchRemoteDataSourceImpl({required this.client});

  // Método auxiliar para manejar los códigos de estado HTTP y lanzar excepciones
  void _handleStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
        throw const UnauthorizedException(); // Usando const
      case 403:
        throw const ForbiddenException(); // Usando const
      case 404:
        throw const NotFoundException(); // Usando const
      case 409:
        throw const ConflictException(); // Usando const
      default:
        throw const ServerException(); // Usando const
    }
  }

  @override
  Future<MatchModel> scheduleFriendlyMatch(
      {required DateTime time, required String fieldId}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/matches'), // Usando baseUrl
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'time': time.toIso8601String(),
        'fieldId': fieldId,
      }),
    );

    if (response.statusCode == 201) { 
      return MatchModel.fromJson(json.decode(response.body));
    } else {
      _handleStatusCode(response.statusCode);
      throw const ServerException(); 
    }
  }

  @override
  Future<List<MatchModel>> getUpcomingMatches() async {
    final response = await client.get(
      Uri.parse('$baseUrl/matches/upcoming'), // Usando baseUrl
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => MatchModel.fromJson(json)).toList();
    } else {
      _handleStatusCode(response.statusCode);
      throw const ServerException();
    }
  }

  @override
  Future<MatchModel> addPlayerToMatch(
      {required String matchId, required String playerId}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/matches/$matchId/join'), // Usando baseUrl
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'playerId': playerId
      }),
    );

    if (response.statusCode == 200) {
      return MatchModel.fromJson(json.decode(response.body));
    } else {
      _handleStatusCode(response.statusCode);
      throw const ServerException();
    }
  }

  // ==============================================================
  // IMPLEMENTACIONES AÑADIDAS
  // ==============================================================

  @override
  Future<MatchModel> getMatchById(String matchId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/matches/$matchId'), // Usando baseUrl
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return MatchModel.fromJson(json.decode(response.body));
    } else {
      _handleStatusCode(response.statusCode);
      throw const ServerException();
    }
  }

  @override
  Future<MatchModel> updateMatchTeams({
    required String matchId,
    required TeamModel teamA,
    required TeamModel teamB,
  }) async {
    final response = await client.put( 
      Uri.parse('$baseUrl/matches/$matchId/teams'), // Usando baseUrl
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'teamA': teamA.toJson(), 
        'teamB': teamB.toJson(),
      }),
    );

    if (response.statusCode == 200) {
      return MatchModel.fromJson(json.decode(response.body));
    } else {
      _handleStatusCode(response.statusCode);
      throw const ServerException();
    }
  }
}