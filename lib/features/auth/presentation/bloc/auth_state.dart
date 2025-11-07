part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

/// Estado inicial (antes de la verificación)
class AuthInitial extends AuthState {}

/// Estado de carga (durante la verificación o la llamada a la API)
class AuthLoading extends AuthState {}

/// El usuario está autenticado
class AuthAuthenticated extends AuthState {
  final String userId;
  const AuthAuthenticated(this.userId);
  @override
  List<Object> get props => [userId];
}

/// El usuario no está autenticado
class AuthUnauthenticated extends AuthState {}

/// Ocurrió un error en la autenticación
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}