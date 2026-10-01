import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_pro/features/league_management/domain/entities/league_detail.dart';
import 'package:futbol_pro/features/field_management/domain/entities/booking.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/match_split.dart';

void main() {
  group('Fase 3 parses', () {
    test('FixtureEntry detecta jugado/no jugado', () {
      final jugado = FixtureEntry.fromJson({
        'jornada': 1,
        'equipoA': {'id': '1', 'nombre': 'Tigres'},
        'equipoB': {'id': '2', 'nombre': 'Leones'},
        'matchId': '9',
        'status': 'FINALIZADO',
        'golesA': 2,
        'golesB': 2,
      });
      expect(jugado.jugado, isTrue);

      const pendiente = FixtureEntry(
        jornada: 2,
        equipoAId: '1',
        equipoANombre: 'Tigres',
        equipoBId: '3',
        equipoBNombre: 'Pumas',
      );
      expect(pendiente.jugado, isFalse);
    });

    test('ScorerRow orden se mantiene por goles (parse)', () {
      final s = ScorerRow.fromJson({
        'playerId': '5',
        'name': 'Goleador',
        'goles': 4,
      });
      expect(s.goles, 4);
    });

    test('BookingInfo.parsea economía de reserva', () {
      final b = BookingInfo.fromJson({
        'reservaId': '12',
        'fieldId': '1',
        'fieldName': 'Campo Central',
        'total': 1200,
        'sena': 240,
        'senaPct': 0.2,
        'estado': 'pendiente',
        'pago': {'id': '7', 'providerRef': 'MOCK-1'},
      });
      expect(b.senaPagada, isFalse);
      expect(b.pagoId, '7');
      expect(b.sena, 240);

      const pagada = BookingInfo(
        reservaId: '12',
        fieldId: '1',
        fieldName: 'Campo Central',
        total: 100,
        sena: 20,
        estado: 'senada',
      );
      expect(pagada.senaPagada, isTrue);
    });

    test('MatchSplit calcula por persona', () {
      final s = MatchSplit.fromJson({
        'matchId': '3',
        'total': 100,
        'hasCost': true,
        'participants': 2,
        'perPerson': 50,
        'detail': [
          {'id': '1', 'name': 'A', 'amount': 50},
          {'id': '2', 'name': 'B', 'amount': 50},
        ],
      });
      expect(s.perPerson, 50);
      expect(s.detail.length, 2);
    });
  });
}
