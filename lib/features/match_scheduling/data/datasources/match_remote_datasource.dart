import 'package:http/http.dart'
    as http; // Necesario para la implementación de la API REST
import 'dart:convert'; // Necesario para codificar/decodificar JSON

import '../models/match_model.dart';
import '../models/team_model.dart';
import '../../domain/entities/match_acta.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/entities/match_split.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/consts.dart'; // 🚀 IMPORT CORREGIDO A AppConsts

abstract class MatchRemoteDataSource {
  /// Programa un nuevo partido amistoso.
  /// Llama al endpoint de la API REST para crear un partido.
  /// [mode]: 'open' (jugadores sueltos) | 'team' (equipo completo).
  Future<MatchModel> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
    String title = 'Amistoso',
    String mode = 'open',
    bool needsReferee = false,
    String? description,
    String? organizerTeamName,
    String? opponentTeamName,
    int? maxPlayers,
    double? costeTotal,
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

  /// Propone el resultado final (solo participantes).
  Future<MatchResult> submitResult({
    required String matchId,
    required int golesA,
    required int golesB,
    String ganador = 'empate',
    List<ScorerEntry> goleadores = const [],
    List<String> teamAIds = const [],
    List<String> teamBIds = const [],
    String? mvpId,
  });

  /// Confirma una propuesta (otro participante o superadmin).
  Future<MatchResult> confirmResult({required String matchId});

  /// Reporta inasistencia de un participante.
  Future<int> reportNoShow({required String matchId, required String playerId});

  /// División de la cuenta entre participantes.
  Future<MatchSplit> getSplit({required String matchId});

  /// Acta del partido (solo participantes / superadmin).
  Future<MatchActa> getActa({required String matchId});
}

// ===============================================
// 💡 IMPLEMENTACIÓN DEL DATASOURCE
// ===============================================

class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final http.Client client;

  MatchRemoteDataSourceImpl({required this.client});

  // Método auxiliar para manejar respuestas de API (con cuerpo en errores).
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      throw ValidationException(
        message: response.body.substring(
          0,
          response.body.length > 500 ? 500 : response.body.length,
        ),
      );
    } else if (response.statusCode == 401) {
      throw UnauthorizedException(message: 'No autorizado.');
    } else if (response.statusCode == 403) {
      throw ForbiddenException(message: 'Sin permiso.');
    } else if (response.statusCode == 404) {
      throw NotFoundException(message: 'No encontrado.');
    } else if (response.statusCode == 409) {
      throw ConflictException(
        message: response.body.substring(
          0,
          response.body.length > 500 ? 500 : response.body.length,
        ),
      );
    } else {
      throw ServerException(
        message:
            'Error ${response.statusCode}: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );
    }
  }

  @override
  Future<MatchModel> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
    String title = 'Amistoso',
    String mode = 'open',
    bool needsReferee = false,
    String? description,
    String? organizerTeamName,
    String? opponentTeamName,
    int? maxPlayers,
    double? costeTotal,
  }) async {
    final response = await client.post(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'scheduledTime': time.toIso8601String(),
        'time': time.toIso8601String(),
        'fieldId': fieldId,
        'title': title,
        'mode': mode,
        'needsReferee': needsReferee,
        if (description != null) 'description': description,
        if (organizerTeamName != null) 'organizerTeam': organizerTeamName,
        if (opponentTeamName != null) 'opponentTeam': opponentTeamName,
        if (maxPlayers != null) 'maxPlayers': maxPlayers,
        if (costeTotal != null) 'costeTotal': costeTotal,
      }),
    );
    final data = _handleResponse(response);
    return MatchModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<MatchModel>> getUpcomingMatches() async {
    final response = await client.get(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/upcoming'),
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
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/$matchId/join'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'playerId': playerId}),
    );
    final data = _handleResponse(response);
    return MatchModel.fromJson(data);
  }

  @override
  Future<MatchModel> getMatchById(String matchId) async {
    final response = await client.get(
      // 🚀 NOMBRE DE LA CLASE CORREGIDO
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/$matchId'),
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
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/$matchId/teams'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'teamA': teamA.toJson(), 'teamB': teamB.toJson()}),
    );
    final data = _handleResponse(response);
    return MatchModel.fromJson(data);
  }

  MatchResult _parseResult(http.Response response) {
    final data = _handleResponse(response);
    return MatchResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<MatchResult> submitResult({
    required String matchId,
    required int golesA,
    required int golesB,
    String ganador = 'empate',
    List<ScorerEntry> goleadores = const [],
    List<String> teamAIds = const [],
    List<String> teamBIds = const [],
    String? mvpId,
  }) async {
    final response = await client.post(
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/$matchId/result'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'golesA': golesA,
        'golesB': golesB,
        'ganador': ganador,
        'goleadores': goleadores.map((g) => g.toJson()).toList(),
        'teamAIds': teamAIds,
        'teamBIds': teamBIds,
        if (mvpId != null) 'mvpId': mvpId,
      }),
    );
    return _parseResult(response);
  }

  @override
  Future<MatchResult> confirmResult({required String matchId}) async {
    final response = await client.post(
      Uri.parse(
        '${AppConsts.effectiveBaseUrl}/matches/$matchId/result/confirm',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    return _parseResult(response);
  }

  @override
  Future<int> reportNoShow({
    required String matchId,
    required String playerId,
  }) async {
    final response = await client.post(
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/$matchId/no-show'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'playerId': playerId}),
    );
    final data = _handleResponse(response);
    return (data['noShows'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<MatchSplit> getSplit({required String matchId}) async {
    final response = await client.get(
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/$matchId/split'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = _handleResponse(response);
    return MatchSplit.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<MatchActa> getActa({required String matchId}) async {
    final response = await client.get(
      Uri.parse('${AppConsts.effectiveBaseUrl}/matches/$matchId/acta'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = _handleResponse(response);
    return MatchActa.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
