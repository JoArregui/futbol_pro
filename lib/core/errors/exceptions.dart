// Excepciones de la capa de Datos
class ServerException implements Exception {
  final String message;
  // 🆕 Constructor const añadido
  const ServerException({this.message = 'Error en el servidor'}); 
}

class CacheException implements Exception {
  final String message;
  // 🆕 Constructor const añadido
  const CacheException({this.message = 'Error de caché'});
}

// 💡 EXCEPCIÓN AÑADIDA: Para manejar el estado de no autenticado en la capa de datos
class UnauthenticatedException implements Exception {
  // 🆕 Constructor const añadido
  const UnauthenticatedException(); 
}

// Excepciones HTTP o de lógica de negocio (Errores comunes de la API)
class UnauthorizedException implements Exception {
  // 🆕 Constructor const añadido
  const UnauthorizedException(); 
} 
class ForbiddenException implements Exception {
  // 🆕 Constructor const añadido
  const ForbiddenException();
}
class NotFoundException implements Exception {
  // 🆕 Constructor const añadido
  const NotFoundException();
} 
class ConflictException implements Exception {
  // 🆕 Constructor const añadido
  const ConflictException();
}