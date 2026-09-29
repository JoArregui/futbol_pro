import 'package:http/http.dart' as http;
import 'dart:convert'; // Necesario para jsonDecode
import '../models/standing_model.dart';
import '../models/tournament_model.dart';
import '../../domain/entities/league_detail.dart';
import 'package:futbol_pro/core/errors/exceptions.dart'; // Asegúrate de tener tu archivo de excepciones

import 'package:futbol_pro/core/consts.dart';
final String _kBaseUrl = '${AppConsts.effectiveBaseUrl}/leagues';

abstract class LeagueRemoteDataSource {
  Future<List<StandingModel>> fetchLeagueStandings({required String leagueId});
  Future<List<TournamentModel>> fetchTournaments();
  Future<bool> registerTeam(
      {required String leagueId, required String teamName});
  Future<TournamentModel> createLeague(
      {required String nombre, String descripcion = '', int maxEquipos = 12});
  Future<List<LeagueTeam>> fetchLeagueTeams({required String leagueId});
  Future<Map<String, dynamic>> generateFixture({required String leagueId});
  Future<List<FixtureEntry>> fetchFixture({required String leagueId});
  Future<List<ScorerRow>> fetchScorers({required String leagueId});
}

class LeagueRemoteDataSourceImpl implements LeagueRemoteDataSource {
  final http.Client client;

  LeagueRemoteDataSourceImpl({required this.client});

  // ==================================================
  // OBTENER CLASIFICACIÓN (GET a la API)
  // ==================================================
  @override
  Future<List<StandingModel>> fetchLeagueStandings({required String leagueId}) async {
    // 1. Construir la URL con el ID de la liga
    final url = Uri.parse('$_kBaseUrl/$leagueId/standings');

    try {
      final response = await client.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        // 2. Decodificar la lista de clasificación (la API devuelve un array JSON)
        final List<dynamic> jsonList = jsonDecode(response.body);
        
        // 3. Mapear a StandingModel
        return jsonList.map((json) => StandingModel.fromJson(json)).toList();
        
      } else if (response.statusCode == 404) {
        // Si la liga no existe o no tiene datos
        return []; 
      } else {
        // Manejar otros errores del servidor
        throw ServerException(message: 'Error al obtener la clasificación: ${response.statusCode}');
      }
    } on Exception catch (e) {
      // Manejar errores de conexión de red
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<List<TournamentModel>> fetchTournaments() async {
    final url = Uri.parse(_kBaseUrl);
    try {
      final response =
          await client.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((j) =>
                TournamentModel.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      }
      throw ServerException(
          message: 'Error al obtener torneos: ${response.statusCode}');
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al servidor: $e');
    }
  }

  @override
  Future<bool> registerTeam(
      {required String leagueId, required String teamName}) async {
    final url = Uri.parse('$_kBaseUrl/$leagueId/register');
    final response = await client.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'teamName': teamName}));
    if (response.statusCode == 201 || response.statusCode == 200) return true;
    if (response.statusCode == 409) {
      throw const ServerException(message: 'Equipo ya inscrito o cupo lleno.');
    }
    throw ServerException(
        message: 'Error al inscribir equipo: ${response.statusCode}');
  }

  @override
  Future<TournamentModel> createLeague(
      {required String nombre,
      String descripcion = '',
      int maxEquipos = 12}) async {
    final response = await client.post(
      Uri.parse(_kBaseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'max_equipos': maxEquipos,
      }),
    );
    if (response.statusCode == 201) {
      final j = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      return TournamentModel(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? nombre).toString(),
        description: descripcion,
        startDate: DateTime.now(),
        maxTeams: maxEquipos,
        registeredTeams: 0,
        status: 'open',
      );
    }
    if (response.statusCode == 403) {
      throw const ServerException(message: 'Solo superadmin puede crear ligas.');
    }
    throw ServerException(
        message: 'Error al crear liga: ${response.statusCode}');
  }

  @override
  Future<List<LeagueTeam>> fetchLeagueTeams(
      {required String leagueId}) async {
    final response = await client.get(
        Uri.parse('$_kBaseUrl/$leagueId/teams'),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list
          .map((j) =>
              LeagueTeam.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw ServerException(
        message: 'Error al obtener equipos: ${response.statusCode}');
  }

  @override
  Future<Map<String, dynamic>> generateFixture(
      {required String leagueId}) async {
    final response = await client.post(
        Uri.parse('$_kBaseUrl/$leagueId/fixture'),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    if (response.statusCode == 409) {
      throw const ServerException(message: 'El fixture ya fue generado.');
    }
    if (response.statusCode == 400) {
      throw const ServerException(
          message: 'Se necesitan al menos 2 equipos.');
    }
    throw ServerException(
        message: 'Error al generar fixture: ${response.statusCode}');
  }

  @override
  Future<List<FixtureEntry>> fetchFixture({required String leagueId}) async {
    final response = await client.get(
        Uri.parse('$_kBaseUrl/$leagueId/fixture'),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list
          .map((j) =>
              FixtureEntry.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw ServerException(
        message: 'Error al obtener fixture: ${response.statusCode}');
  }

  @override
  Future<List<ScorerRow>> fetchScorers({required String leagueId}) async {
    final response = await client.get(
        Uri.parse('$_kBaseUrl/$leagueId/scorers'),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list
          .map((j) =>
              ScorerRow.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw ServerException(
        message: 'Error al obtener goleadores: ${response.statusCode}');
  }
}