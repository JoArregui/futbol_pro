// Excepciones de la capa de Datos
class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'Error en el servidor'});
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Error de caché'});
}

// 💡 EXCEPCIÓN AÑADIDA: Para manejar el estado de no autenticado en la capa de datos
class UnauthenticatedException implements Exception {
  const UnauthenticatedException();
}

// Excepciones HTTP o de lógica de negocio (Errores comunes de la API)
class UnauthorizedException implements Exception {} 
class ForbiddenException implements Exception {}
class NotFoundException implements Exception {} 
class ConflictException implements Exception {}