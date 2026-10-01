import 'dart:async';
import 'package:http/http.dart' as http;
import '../consts.dart';
import '../errors/exceptions.dart';
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

  Future<bool>? _refreshing;

  @override
  void close() => _inner.close();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // /auth/refresh nunca lleva access (evita rechazos por token caducado).
    final isRefresh = request.url.path.endsWith('/auth/refresh');
    if (!request.headers.containsKey('Authorization') && !isRefresh) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    } else if (isRefresh) {
      request.headers.remove('Authorization');
    }
    var response =
        await _inner.send(request).timeout(AppConsts.httpTimeout);

    // Rotación transparente con mutex: un solo refresh aunque haya N 401.
    if (response.statusCode == 401 &&
        !_isPublicAuthPath(request.url) &&
        onUnauthorized != null) {
      await response.stream.drain<void>();
      bool rotated = false;
      try {
        _refreshing ??= onUnauthorized!().whenComplete(() => _refreshing = null);
        rotated = await _refreshing!;
      } catch (_) {
        rotated = false;
      }
      if (rotated) {
        try {
          final retry = _copyRequest(request);
          final fresh = await _storage.getToken();
          if (fresh != null && fresh.isNotEmpty) {
            retry.headers['Authorization'] = 'Bearer $fresh';
          }
          response =
              await _inner.send(retry).timeout(AppConsts.httpTimeout);
        } on StateError {
          // Multipart u otro one-shot no reintentable: no devolver el
          // response drenado (body vacío); forzar re-login aguas arriba.
          throw const UnauthorizedException(message: 'Sesión caducada.');
        }
      }
    }
    return response;
  }

  /// Reconstruye la petición para el reintento (los BaseRequest son one-shot).
  /// Solo se reintenta http.Request. MultipartRequest no se reintenta
  /// (obligaría a reabrir files) → el llamador debe relanzar login.
  http.BaseRequest _copyRequest(http.BaseRequest original) {
    if (original is! http.Request) {
      throw StateError(
          'No se puede reintentar ${original.runtimeType}: reloguear.');
    }
    final copy = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
    copy.bodyBytes = original.bodyBytes;
    copy.encoding = original.encoding;
    return copy;
  }
}
