// Excepciones de la capa de Datos
class ServerException implements Exception {}

class CacheException implements Exception {}

// Excepciones HTTP o de lógica de negocio
class UnauthorizedException implements Exception {}

class ForbiddenException implements Exception {} // <-- Usada en tu código

class NotFoundException implements Exception {}
