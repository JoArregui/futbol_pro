part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// Estados iniciales/de carga
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

// Estado cuando el usuario no ha iniciado sesión
class AuthUnauthenticated extends AuthState {}

// Estado cuando el usuario ha iniciado sesión con éxito
class AuthAuthenticated extends AuthState {
  final Player player;
  
  const AuthAuthenticated({required this.player});
  
  @override
  List<Object> get props => [player];
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError({required this.message});
  
  @override
  List<Object> get props => [message];
}