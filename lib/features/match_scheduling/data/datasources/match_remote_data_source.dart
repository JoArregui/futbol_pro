import '../models/match_model.dart';
import 'package:app_liga_semiprofesional/core/error/exceptions.dart'; 

abstract class MatchRemoteDataSource {
  Future<MatchModel> scheduleFriendlyMatch(
      {required DateTime time, required String fieldId});
  Future<List<MatchModel>> getUpcomingMatches();
  
  // ¡NUEVO MÉTODO!
  Future<MatchModel> addPlayerToMatch(
      {required String matchId, required String playerId});
}