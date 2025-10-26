import '../models/standing_model.dart';

/// Contrato para la comunicación con la API (Fuente de Datos Remota).
///
/// La implementación de esta interfaz (e.g., LeagueRemoteDataSourceImpl)
/// es donde se realiza la llamada HTTP real y se lanzan las excepciones (Exceptions).
abstract class LeagueRemoteDataSource {
  /// Obtiene la tabla de posiciones (clasificación) de una liga específica.
  ///
  /// Lanza [ServerException] si la llamada falla (ej. error 404, 500, timeout).
  Future<List<StandingModel>> fetchLeagueStandings({required String leagueId});

  // Aquí puedes añadir más métodos, por ejemplo:
  // Future<LeagueModel> fetchLeagueDetails({required String leagueId});
}
