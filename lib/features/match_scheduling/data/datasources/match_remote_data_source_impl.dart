import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import 'match_remote_data_source.dart';


class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final http.Client client;

  MatchRemoteDataSourceImpl({required this.client});

  @override
  Future<MatchModel> addPlayerToMatch(
      {required String matchId, required String playerId}) async {
    final response = await client.post(
      Uri.parse('TU_API_URL/matches/$matchId/join'),
      headers: {'Content-Type': 'application/json'},
      body: '{"playerId": "$playerId"}',
    );

    if (response.statusCode == 200) {
      // El backend devuelve el objeto Match actualizado
      return MatchModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 409) {
      // Conflicto: Jugador ya inscrito o partido lleno
      throw ConflictException();
    } else {
      throw ServerException();
    }
  }
  // ... (otros métodos)
}