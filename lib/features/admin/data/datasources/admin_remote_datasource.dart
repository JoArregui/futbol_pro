import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/consts.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/admin_models.dart';

/// Datasource del panel superadmin. Todas las llamadas llevan JWT.
class AdminRemoteDataSource {
  final http.Client client;
  final AuthRepository authRepository;

  AdminRemoteDataSource({required this.client, required this.authRepository});

  Future<Map<String, String>> _headers() async {
    final token = await authRepository.getAuthToken();
    if (token == null || token.isEmpty) {
      throw const ServerException(message: 'Sin sesión. Inicia sesión.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String get _base => '${AppConsts.effectiveBaseUrl}/admin';

  Future<AdminStats> getStats() async {
    final res = await client.get(Uri.parse('$_base/stats'),
        headers: await _headers());
    if (res.statusCode == 200) {
      return AdminStats.fromJson(
          Map<String, dynamic>.from(jsonDecode(res.body) as Map));
    }
    if (res.statusCode == 403) {
      throw const ServerException(message: 'Solo superadmin.');
    }
    throw ServerException(message: 'Error stats: ${res.statusCode}');
  }

  Future<List<AdminUser>> getUsers({String query = ''}) async {
    final uri = Uri.parse('$_base/users').replace(queryParameters: {
      'q': query,
      'limit': '100',
    });
    final res =
        await client.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .map((j) => AdminUser.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw ServerException(message: 'Error usuarios: ${res.statusCode}');
  }

  Future<int> bulkRole({required List<String> ids, required String role}) async {
    final res = await client.put(Uri.parse('$_base/users/bulk-role'),
        headers: await _headers(),
        body: jsonEncode({'ids': ids, 'role': role}));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['updated'] as int? ?? ids.length;
    }
    throw ServerException(message: 'Error rol masivo: ${res.statusCode}');
  }

  Future<int> bulkDelete({required List<String> ids}) async {
    final res = await client.delete(Uri.parse('$_base/users/bulk'),
        headers: await _headers(), body: jsonEncode({'ids': ids}));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['deleted'] as int? ?? ids.length;
    }
    throw ServerException(message: 'Error borrado masivo: ${res.statusCode}');
  }

  Future<List<AdminMatch>> getMatches() async {
    final res = await client.get(Uri.parse('$_base/matches?limit=100'),
        headers: await _headers());
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .map((j) => AdminMatch.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw ServerException(message: 'Error partidos: ${res.statusCode}');
  }

  Future<int> bulkCancelMatches({required List<String> ids}) async {
    final res = await client.post(Uri.parse('$_base/matches/bulk-cancel'),
        headers: await _headers(), body: jsonEncode({'ids': ids}));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['updated'] as int? ?? ids.length;
    }
    throw ServerException(message: 'Error cancelar: ${res.statusCode}');
  }
}
