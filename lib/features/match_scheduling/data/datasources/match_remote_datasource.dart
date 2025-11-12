import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';

const String baseUrl = 'https://tu-api-backend.com/api/v1';

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

class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final http.Client client;

  MatchRemoteDataSourceImpl({required this.client});

  void _handleStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
        throw const UnauthorizedException();
      case 403:
        throw const ForbiddenException();
      case 404:
        throw const NotFoundException();
      case 409:
        throw const ConflictException();
      default:
        throw const ServerException();
    }
  }

  @override
  Future<MatchModel> scheduleFriendlyMatch(
      {required DateTime time, required String fieldId}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/matches'),
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
      Uri.parse('$baseUrl/matches/upcoming'),
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
      Uri.parse('$baseUrl/matches/$matchId/join'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'playerId': playerId}),
    );

    if (response.statusCode == 200) {
      return MatchModel.fromJson(json.decode(response.body));
    } else {
      _handleStatusCode(response.statusCode);
      throw const ServerException();
    }
  }

  @override
  Future<MatchModel> getMatchById(String matchId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/matches/$matchId'),
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
      Uri.parse('$baseUrl/matches/$matchId/teams'),
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
