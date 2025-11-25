// Excepciones de la capa de Datos
class ServerException implements Exception {
  final String message;
  // Constructor const añadido
  const ServerException({this.message = 'Error en el servidor'}); 
}

class CacheException implements Exception {
  final String message;
  // Constructor const añadido
  const CacheException({this.message = 'Error de caché'});
}

// 💡 EXCEPCIÓN AÑADIDA: Para manejar el estado de no autenticado en la capa de datos
class UnauthenticatedException implements Exception {
  final String? message;
  // 🟢 CORRECCIÓN: Ahora acepta un mensaje nombrado opcional.
  const UnauthenticatedException({this.message}); 
}

// Excepciones HTTP o de lógica de negocio (Errores comunes de la API)
class UnauthorizedException implements Exception {
  final String? message;
  // 🟢 CORRECCIÓN: Ahora acepta un mensaje nombrado opcional.
  const UnauthorizedException({this.message}); 
} 
class ForbiddenException implements Exception {
  final String? message;
  // 🟢 CORRECCIÓN: Ahora acepta un mensaje nombrado opcional.
  const ForbiddenException({this.message});
}
class NotFoundException implements Exception {
  final String? message;
  // 🟢 CORRECCIÓN: Ahora acepta un mensaje nombrado opcional.
  const NotFoundException({this.message});
} 
class ConflictException implements Exception {
  final String? message;
  // 🟢 CORRECCIÓN: Ahora acepta un mensaje nombrado opcional.
  const ConflictException({this.message});
}