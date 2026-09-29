import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_pro/features/match_scheduling/data/models/match_model.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/match_result.dart';

void main() {
  group('MatchResult', () {
    test('fromJson parsea propuesta completa', () {
      final r = MatchResult.fromJson({
        'matchId': '7',
        'golesA': 3,
        'golesB': 1,
        'ganador': 'A',
        'goleadores': [
          {'playerId': '1', 'goles': 2},
        ],
        'teamAIds': ['1'],
        'teamBIds': ['2'],
        'mvpId': '2',
        'propuestoPor': '1',
        'estado': 'propuesta',
      });
      expect(r.scoreLine(), '3 - 1');
      expect(r.isConfirmed, isFalse);
      expect(r.goleadores.single.goles, 2);
      expect(r.mvpId, '2');
    });

    test('MatchModel integra result + participantes enriquecidos', () {
      final m = MatchModel.fromJson({
        'id': '7',
        'title': 'Amistoso',
        'time': '2026-10-01T18:00:00.000',
        'fieldId': '1',
        'status': 'FINALIZADO',
        'golesA': 3,
        'golesB': 1,
        'mvpId': '2',
        'participants': [
          {
            'id': '1',
            'name': 'Cap A',
            'nickname': 'capa',
            'played': 5,
            'wins': 3,
            'mvpCount': 1,
            'noShows': 0
          },
          {'id': '2', 'name': 'Cap B', 'nickname': 'capb'},
        ],
        'result': {
          'matchId': '7',
          'golesA': 3,
          'golesB': 1,
          'ganador': 'A',
          'propuestoPor': '1',
          'estado': 'confirmado',
        },
      });
      expect(m.participants.length, 2);
      expect(m.participants.first.wins, 3);
      expect(m.result?.isConfirmed, isTrue);
      // playerIds fusiona la lista enriquecida sin basura
      expect(m.playerIds.toSet(), {'1', '2'});
    });
  });
}
