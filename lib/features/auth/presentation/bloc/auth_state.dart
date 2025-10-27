part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

/// Estado inicial (antes de cualquier verificación)
class AuthInitial extends AuthState {}

/// Estado durante la carga (login, logout, verificación)
class AuthLoading extends AuthState {}

/// Estado cuando la sesión está activa
class AuthAuthenticated extends AuthState {
  final Player player;

  const AuthAuthenticated({required this.player});

  @override
  List<Object> get props => [player];
}

/// Estado cuando no hay sesión activa o fue cerrada
class AuthUnauthenticated extends AuthState {}

/// Estado de error
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}
