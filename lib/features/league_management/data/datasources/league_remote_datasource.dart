import 'package:http/http.dart' as http;
import '../models/standing_model.dart';

// Contrato para la comunicación con la API
abstract class LeagueRemoteDataSource {
  Future<List<StandingModel>> fetchLeagueStandings({required String leagueId});
}

class LeagueRemoteDataSourceImpl implements LeagueRemoteDataSource {
  final http.Client client;

  // ✅ CORREGIDO: El constructor ahora acepta 'client' como parámetro nombrado.
  LeagueRemoteDataSourceImpl({required this.client});

  @override
  Future<List<StandingModel>> fetchLeagueStandings({required String leagueId}) async {
    // Simulación de latencia
    await Future.delayed(const Duration(milliseconds: 700));

    // Datos Mock: Tabla de posiciones
    final mockData = [
      {"teamName": "Los Invencibles", "points": 45, "wins": 14, "losses": 1, "draws": 3},
      {"teamName": "Rayos FC", "points": 38, "wins": 11, "losses": 3, "draws": 5},
      {"teamName": "Furia Roja", "points": 30, "wins": 8, "losses": 5, "draws": 6},
    ];

    return mockData.map((json) => StandingModel.fromJson(json)).toList();
  }
}
