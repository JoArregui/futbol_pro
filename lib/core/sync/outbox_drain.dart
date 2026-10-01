import '../../features/match_scheduling/data/datasources/match_remote_datasource.dart';
import '../../features/match_scheduling/domain/entities/match_result.dart';
import '../injection_container.dart';
import 'outbox_service.dart';

/// Reenvía la cola offline contra la API real.
/// Llamar al recuperar conexión o desde el botón "Reintentar".
Future<({int ok, int failed})> drainOutbox() async {
  final outbox = sl<OutboxService>();
  final remote = sl<MatchRemoteDataSource>();
  return outbox.drain((action) async {
    final p = action.payload;
    switch (action.kind) {
      case 'join_match':
        await remote.addPlayerToMatch(
          matchId: (p['matchId'] ?? '').toString(),
          playerId: (p['playerId'] ?? '').toString(),
        );
        break;
      case 'submit_result':
        final scorers = ((p['goleadores'] as List?) ?? [])
            .map((e) =>
                ScorerEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        await remote.submitResult(
          matchId: (p['matchId'] ?? '').toString(),
          golesA: (p['golesA'] as num?)?.toInt() ?? 0,
          golesB: (p['golesB'] as num?)?.toInt() ?? 0,
          ganador: (p['ganador'] ?? 'empate').toString(),
          goleadores: scorers,
          teamAIds: ((p['teamAIds'] as List?) ?? [])
              .map((e) => e.toString())
              .toList(),
          teamBIds: ((p['teamBIds'] as List?) ?? [])
              .map((e) => e.toString())
              .toList(),
          mvpId: p['mvpId']?.toString(),
        );
        break;
      case 'confirm_result':
        await remote.confirmResult(matchId: (p['matchId'] ?? '').toString());
        break;
      case 'report_no_show':
        await remote.reportNoShow(
          matchId: (p['matchId'] ?? '').toString(),
          playerId: (p['playerId'] ?? '').toString(),
        );
        break;
      default:
        // Tipo desconocido (versión vieja): descartar sin reintentar.
        break;
    }
  });
}
