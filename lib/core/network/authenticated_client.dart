import 'package:http/http.dart' as http;
import '../storage/secure_storage_service.dart';

/// Cliente HTTP que inyecta el JWT en cada petición.
///
/// - Lee el token de [SecureStorageService] (persistido tras login/register).
/// - Si la petición ya trae `Authorization`, la respeta (p. ej. Admin datasource
///   que construye sus propios headers).
/// - Las rutas públicas (`/auth/login`, `/auth/register`, `/auth/refresh`)
///   salen sin header si aún no hay token; el backend las permite.
/// - Ante un 401 en una ruta protegida, ejecuta [onUnauthorized] una vez
///   (rotación con refresh token) y reintenta la petición con el token nuevo.
/// - Sin token válido el backend devuelve 401: nunca hay acceso anónimo.
class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final SecureStorageService _storage;

  /// Hook de rotación. Se inyecta en el DI para evitar ciclo de dependencias.
  /// Debe devolver true si consiguió un access token nuevo.
  Future<bool> Function()? onUnauthorized;

  AuthenticatedClient({
    required http.Client inner,
    required SecureStorageService storage,
    this.onUnauthorized,
  })  : _inner = inner,
        _storage = storage;

  static bool _isPublicAuthPath(Uri url) {
    final p = url.path;
    return p.endsWith('/auth/login') ||
        p.endsWith('/auth/register') ||
        p.endsWith('/auth/refresh');
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.headers.containsKey('Authorization')) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    var response = await _inner.send(request);

    // Rotación transparente: un solo reintento por petición.
    if (response.statusCode == 401 &&
        !_isPublicAuthPath(request.url) &&
        onUnauthorized != null) {
      await response.stream.drain<void>();
      bool rotated = false;
      try {
        rotated = await onUnauthorized!();
      } catch (_) {
        rotated = false;
      }
      if (rotated) {
        final retry = _copyRequest(request);
        final fresh = await _storage.getToken();
        if (fresh != null && fresh.isNotEmpty) {
          retry.headers['Authorization'] = 'Bearer $fresh';
        }
        response = await _inner.send(retry);
      }
    }
    return response;
  }

  /// Reconstruye la petición para el reintento (los BaseRequest son one-shot).
  http.BaseRequest _copyRequest(http.BaseRequest original) {
    final copy = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
    if (original is http.Request) {
      copy.bodyBytes = original.bodyBytes;
    }
    return copy;
  }
}
