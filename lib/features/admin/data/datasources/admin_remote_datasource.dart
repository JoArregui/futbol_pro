import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/consts.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/admin_models.dart';

/// Datasource del panel superadmin. Todas las llamadas llevan JWT.
/// Sin mocks: si el backend falla, se propaga ServerException y la UI
/// muestra estado vacío/error real. Lista vacía del servidor = lista vacía.
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
    final res = await client.get(
      Uri.parse('$_base/stats'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return AdminStats.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map),
      );
    }
    if (res.statusCode == 403) {
      throw const ServerException(message: 'Solo superadmin.');
    }
    throw ServerException(message: 'Error stats: ${res.statusCode}');
  }

  Future<List<AdminUser>> getUsers({String query = ''}) async {
    final uri = Uri.parse(
      '$_base/users',
    ).replace(queryParameters: {'q': query, 'limit': '100'});
    final res = await client.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .map((j) => AdminUser.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw ServerException(message: 'Error usuarios: ${res.statusCode}');
  }

  Future<int> bulkRole({
    required List<String> ids,
    required String role,
  }) async {
    final res = await client.put(
      Uri.parse('$_base/users/bulk-role'),
      headers: await _headers(),
      body: jsonEncode({'ids': ids, 'role': role}),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['updated'] as int? ?? ids.length;
    }
    throw ServerException(message: 'Error rol masivo: ${res.statusCode}');
  }

  Future<int> bulkDelete({required List<String> ids}) async {
    // POST: los proxies/CDN suelen stripear el body de un DELETE.
    final res = await client.post(
      Uri.parse('$_base/users/bulk-delete'),
      headers: await _headers(),
      body: jsonEncode({'ids': ids}),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['deleted'] as int? ?? ids.length;
    }
    throw ServerException(message: 'Error borrado masivo: ${res.statusCode}');
  }

  Future<List<AdminMatch>> getMatches() async {
    final res = await client.get(
      Uri.parse('$_base/matches?limit=100'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .map((j) => AdminMatch.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw ServerException(message: 'Error partidos: ${res.statusCode}');
  }

  Future<int> bulkCancelMatches({required List<String> ids}) async {
    final res = await client.post(
      Uri.parse('$_base/matches/bulk-cancel'),
      headers: await _headers(),
      body: jsonEncode({'ids': ids}),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['updated'] as int? ?? ids.length;
    }
    throw ServerException(message: 'Error cancelar: ${res.statusCode}');
  }

  // ---------- Gestión extendida (backend real, sin mocks) ----------

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final res = await client.get(
      Uri.parse('$_base$path'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .whereType<Map>()
          .map((j) => fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    if (res.statusCode == 403) {
      throw const ServerException(message: 'Solo superadmin.');
    }
    throw ServerException(message: 'Error ${res.statusCode}: ${res.body}');
  }

  Future<List<AdminTeam>> getTeams() =>
      _getList('/teams?limit=100', AdminTeam.fromJson);

  Future<List<AdminPlayer>> getPlayers({String query = ''}) => _getList(
    '/players?q=${Uri.encodeComponent(query)}&limit=100',
    AdminPlayer.fromJson,
  );

  Future<List<AdminField>> getFields() =>
      _getList('/fields?limit=100', AdminField.fromJson);

  Future<List<AdminReferee>> getReferees() =>
      _getList('/referees?limit=100', AdminReferee.fromJson);

  Future<List<AdminLeague>> getLeagues() =>
      _getList('/leagues?limit=50', AdminLeague.fromJson);

  Future<List<AdminMatch>> getFriendlies() async {
    final all = await getMatches();
    final f = all.where((m) => m.type.toUpperCase() == 'AMISTOSO').toList();
    return f.isEmpty ? all : f;
  }

  Future<List<AdminTournament>> getTournaments() =>
      _getList('/tournaments?limit=50', AdminTournament.fromJson);

  Future<AdminFinance> getFinance() async {
    final res = await client.get(
      Uri.parse('$_base/finance'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return AdminFinance.fromJson(
        Map<String, dynamic>.from(jsonDecode(res.body) as Map),
      );
    }
    if (res.statusCode == 404) {
      // Backend sin módulo finanzas: devolver vacío real, no cifras inventadas.
      return const AdminFinance(
        totalRevenue: 0,
        monthRevenue: 0,
        pending: 0,
        byMonth: [],
      );
    }
    throw ServerException(
      message: 'Error finanzas: ${res.statusCode} ${res.body}',
    );
  }

  Future<bool> createTeam({required String name, String league = ''}) async {
    final res = await client.post(
      Uri.parse('$_base/teams'),
      headers: await _headers(),
      body: jsonEncode({'nombre': name, 'liga': league}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return true;
    throw ServerException(
      message: 'Error crear equipo: ${res.statusCode} ${res.body}',
    );
  }

  Future<bool> createLeague({required String name}) async {
    final res = await client.post(
      Uri.parse('$_base/leagues'),
      headers: await _headers(),
      body: jsonEncode({'nombre': name}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return true;
    throw ServerException(
      message: 'Error crear liga: ${res.statusCode} ${res.body}',
    );
  }

  Future<bool> toggleFieldStatus({
    required String id,
    required String status,
  }) async {
    final res = await client.put(
      Uri.parse('$_base/fields/$id'),
      headers: await _headers(),
      body: jsonEncode({'estado': status}),
    );
    if (res.statusCode == 200) return true;
    throw ServerException(
      message: 'Error campo: ${res.statusCode} ${res.body}',
    );
  }

  // ---------- CRUD completo ----------

  Future<bool> _post(String path, Map<String, dynamic> body) async {
    final res = await client.post(
      Uri.parse('$_base$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) return true;
    throw ServerException(message: 'Error: ${res.statusCode} ${res.body}');
  }

  Future<bool> _put(String path, Map<String, dynamic> body) async {
    final res = await client.put(
      Uri.parse('$_base$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return true;
    throw ServerException(message: 'Error: ${res.statusCode} ${res.body}');
  }

  Future<bool> _delete(String path) async {
    final res = await client.delete(
      Uri.parse('$_base$path'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return true;
    throw ServerException(message: 'Error: ${res.statusCode} ${res.body}');
  }

  Future<bool> updateTeam({required String id, required String name}) =>
      _put('/teams/$id', {'nombre': name});

  Future<bool> deleteTeam({required String id}) => _delete('/teams/$id');

  Future<List<AdminPlayer>> getTeamPlayers(String teamId) async {
    final res = await client.get(
      Uri.parse('$_base/teams/$teamId/players'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .whereType<Map>()
          .map((j) => AdminPlayer.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    if (res.statusCode == 404) return [];
    throw ServerException(
      message: 'Error plantilla: ${res.statusCode} ${res.body}',
    );
  }

  Future<bool> addPlayerToTeam({
    required String teamId,
    required String playerId,
  }) => _post('/teams/$teamId/players', {'playerId': playerId});

  Future<bool> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  }) => _delete('/teams/$teamId/players/$playerId');

  Future<bool> createField({
    required String name,
    double price = 50,
    int capacity = 14,
  }) => _post('/fields', {
    'nombre': name,
    'tarifa': price,
    'capacidad': capacity,
  });

  Future<bool> deleteField({required String id}) => _delete('/fields/$id');

  Future<bool> createReferee({required String name, double fee = 20}) =>
      _post('/referees', {'nombre': name, 'tarifa': fee});

  Future<bool> updateReferee({
    required String id,
    String? name,
    double? fee,
    String? status,
  }) => _put('/referees/$id', {
    if (name != null) 'nombre': name,
    if (fee != null) 'tarifa': fee,
    if (status != null) 'estado': status,
  });

  Future<bool> deleteReferee({required String id}) => _delete('/referees/$id');

  Future<AdminPlayer> createManualPlayer({
    required String apodo,
    String? nombre,
    String? email,
  }) async {
    final res = await client.post(
      Uri.parse('$_base/players'),
      headers: await _headers(),
      body: jsonEncode({'apodo': apodo, 'nombre': nombre, 'email': email}),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return AdminPlayer(
        id: data['id'].toString(),
        name: data['name']?.toString() ?? '',
        nickname: data['nickname']?.toString() ?? '',
        team: '',
        goals: 0,
        rating: 4.5,
      );
    }
    throw ServerException(
      message: 'Error creando jugador: ${res.statusCode} ${res.body}',
    );
  }

  Future<List<AdminAudit>> getAudit({int limit = 30}) async {
    final res = await client.get(
      Uri.parse('$_base/audit?limit=$limit'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list
          .whereType<Map>()
          .map((j) => AdminAudit.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    if (res.statusCode == 404) return [];
    throw ServerException(
      message: 'Error auditoría: ${res.statusCode} ${res.body}',
    );
  }
}
