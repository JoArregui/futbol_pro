import 'package:http/http.dart' as http;
import 'dart:convert'; // Necesario para jsonDecode
import '../models/standing_model.dart';
import 'package:futbol_pro/core/errors/exceptions.dart'; // Asegúrate de tener tu archivo de excepciones

// 🟢 URL BASE: Apuntando a tu servidor Node.js
const String _kBaseUrl = 'http://10.0.2.2:3000/api/v1/leagues'; 

abstract class LeagueRemoteDataSource {
  Future<List<StandingModel>> fetchLeagueStandings({required String leagueId});
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
}