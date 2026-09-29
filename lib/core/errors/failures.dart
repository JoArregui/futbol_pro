import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los fallos
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

// Fallos generales
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

// Extensión para mapear excepciones a mensajes amigables
extension FailureExtension on Failure {
  String get errorMessage {
    switch (runtimeType) {
      case ServerFailure _:
        return 'Error del servidor: $message';
      case CacheFailure _:
        return 'Error de almacenamiento local: $message';
      case NetworkFailure _:
        return 'Sin conexión a internet. Verifica tu conexión.';
      case AuthenticationFailure _:
        return 'Error de autenticación: $message';
      case ValidationFailure _:
        return message;
      case PermissionFailure _:
        return 'Permiso denegado: $message';
      case NotFoundFailure _:
        return 'No encontrado: $message';
      default:
        return 'Error inesperado: $message';
    }
  }
}
