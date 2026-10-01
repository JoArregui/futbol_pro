import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:futbol_pro/core/network/authenticated_client.dart';
import 'package:futbol_pro/core/storage/secure_storage_service.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Fake HTTP que responde según una función y registra los headers vistos.
class FakeInner extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest req) handler;
  final List<Map<String, String>> seenHeaders = [];

  FakeInner(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    seenHeaders.add(Map<String, String>.from(request.headers));
    return handler(request);
  }
}

http.StreamedResponse ok(String body, {int code = 200}) {
  final stream = Stream.value(body.codeUnits);
  return http.StreamedResponse(stream, code);
}

void main() {
  late MockSecureStorage mockStorage;
  late SecureStorageService storage;

  setUp(() {
    mockStorage = MockSecureStorage();
    storage = SecureStorageService(storage: mockStorage);
  });

  group('AuthenticatedClient', () {
    test('inyecta Bearer cuando hay token', () async {
      when(
        () => mockStorage.read(key: 'auth_token'),
      ).thenAnswer((_) async => 'abc123');
      final inner = FakeInner((req) async => ok('{}'));
      final client = AuthenticatedClient(inner: inner, storage: storage);

      await client.get(Uri.parse('https://api.test/api/v1/users/1/profile'));

      expect(inner.seenHeaders.single['Authorization'], 'Bearer abc123');
    });

    test('respeta un Authorization ya presente', () async {
      when(
        () => mockStorage.read(key: 'auth_token'),
      ).thenAnswer((_) async => 'nuevo');
      final inner = FakeInner((req) async => ok('{}'));
      final client = AuthenticatedClient(inner: inner, storage: storage);

      await client.get(
        Uri.parse('https://api.test/api/v1/admin/stats'),
        headers: {'Authorization': 'Bearer manual'},
      );

      expect(inner.seenHeaders.single['Authorization'], 'Bearer manual');
    });

    test('ante 401 rota con onUnauthorized y reintenta una vez', () async {
      var calls = 0;
      when(
        () => mockStorage.read(key: 'auth_token'),
      ).thenAnswer((_) async => calls == 0 ? 'expirado' : 'fresco');
      final inner = FakeInner((req) async {
        calls++;
        if (calls == 1) return ok('unauthorized', code: 401);
        return ok('{"ok":true}');
      });
      final client = AuthenticatedClient(inner: inner, storage: storage);
      client.onUnauthorized = () async => true;

      final res = await client.get(
        Uri.parse('https://api.test/api/v1/matches/upcoming'),
      );

      expect(res.statusCode, 200);
      expect(calls, 2);
      expect(inner.seenHeaders[1]['Authorization'], 'Bearer fresco');
    });

    test('no reintenta /auth/refresh (evita bucle)', () async {
      var calls = 0;
      when(
        () => mockStorage.read(key: 'auth_token'),
      ).thenAnswer((_) async => 'x');
      final inner = FakeInner((req) async {
        calls++;
        return ok('expired', code: 401);
      });
      final client = AuthenticatedClient(inner: inner, storage: storage);
      var hookCalls = 0;
      client.onUnauthorized = () async {
        hookCalls++;
        return true;
      };

      final res = await client.post(
        Uri.parse('https://api.test/api/v1/auth/refresh'),
        body: '{"refreshToken":"r"}',
      );

      expect(res.statusCode, 401);
      expect(calls, 1);
      expect(hookCalls, 0);
    });
  });
}
