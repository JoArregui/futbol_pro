import 'package:http/http.dart' as http; // Necesario para la implementación de la API REST
import 'dart:convert'; // Necesario para codificar/decodificar JSON

import '../models/match_model.dart';
import '../models/team_model.dart';
import '../../../../core/errors/exceptions.dart'; 
import '../../../../core/consts.dart'; // 🚀 IMPORT CORREGIDO A AppConsts

abstract class MatchRemoteDataSource {
  
  /// Programa un nuevo partido amistoso.
  /// Llama al endpoint de la API REST para crear un partido.
  Future<MatchModel> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
  });

  /// Obtiene la lista de todos los partidos futuros programados.
  /// Soporta el Use Case: GetUpcomingMatches.
  Future<List<MatchModel>> getUpcomingMatches();

  /// Añade al usuario actual como jugador en un partido.
  /// Llama al endpoint de la API para unirse a un partido.
  Future<MatchModel> addPlayerToMatch({
    required String matchId,
    required String playerId,
  });

  /// Obtiene los detalles de un partido específico por ID.
  /// Soporta el Use Case: GetMatchDetails.
  Future<MatchModel> getMatchById(String matchId);

  /// Envía los equipos balanceados de vuelta al servidor para actualizar el partido.
  /// Soporta el Use Case: UpdateMatchWithTeams.
  Future<MatchModel> updateMatchTeams({
    required String matchId,
    required TeamModel teamA,
    required TeamModel teamB,
  });
}

// ===============================================
// 💡 IMPLEMENTACIÓN DEL DATASOURCE
// ===============================================

class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final http.Client client;

  MatchRemoteDataSourceImpl({required this.client});

  // Método auxiliar para manejar respuestas de API
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      throw ConflictException(message: response.body); 
    } else if (response.statusCode == 401) {
      throw UnauthorizedException();
    } else if (response.statusCode == 403) {
      throw ForbiddenException();
    } else if (response.statusCode == 404) {
      throw NotFoundException();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<MatchModel> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
  }) async {
    final response = await client.post(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.baseUrl}/matches'), 
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'scheduledTime': time.toIso8601String(),
        'fieldId': fieldId,
        // Puede que necesites userId del AuthBloc
      }),
    );
    final data = _handleResponse(response);
    return MatchModel.fromJson(data);
  }
  
  @override
  Future<List<MatchModel>> getUpcomingMatches() async {
    final response = await client.get(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.baseUrl}/matches/upcoming'),
      headers: {'Content-Type': 'application/json'},
    );
    final List<dynamic> jsonList = _handleResponse(response);
    return jsonList.map((json) => MatchModel.fromJson(json)).toList();
  }
  
  @override
  Future<MatchModel> addPlayerToMatch({
    required String matchId,
    required String playerId,
  }) async {
    final response = await client.post(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.baseUrl}/matches/$matchId/join'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'playerId': playerId,
      }),
    );
    final data = _handleResponse(response);
    return MatchModel.fromJson(data);
  }
  
  @override
  Future<MatchModel> getMatchById(String matchId) async {
    final response = await client.get(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.baseUrl}/matches/$matchId'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = _handleResponse(response);
    return MatchModel.fromJson(data);
  }
  
  @override
  Future<MatchModel> updateMatchTeams({
    required String matchId,
    required TeamModel teamA,
    required TeamModel teamB,
  }) async {
    final response = await client.put(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.baseUrl}/matches/$matchId/teams'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'teamA': teamA.toJson(),
        'teamB': teamB.toJson(),
      }),
    );
    final data = _handleResponse(response);
    return MatchModel.fromJson(data);
  }
}