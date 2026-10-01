import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/consts.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/referee.dart';

class RefereeRemoteDataSource {
  final http.Client client;
  RefereeRemoteDataSource({required this.client});

  Future<List<Referee>> getAvailable({required DateTime date}) async {
    final url = Uri.parse(
      '${AppConsts.effectiveBaseUrl}/referees/available?date=${date.toUtc().toIso8601String()}',
    );
    final res = await client.get(url);
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .map((j) => Referee.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    if (res.statusCode == 404) return [];
    throw ServerException(message: 'Error árbitros: ${res.statusCode}');
  }
}
