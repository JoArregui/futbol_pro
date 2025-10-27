part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Evento disparado al iniciar la aplicación para verificar el token
class AppStarted extends AuthEvent {}

/// Evento para iniciar sesión
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

/// ✅ NUEVO: Evento para registrar un nuevo usuario
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String nickname;
  final String? name; // Opcional

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.nickname,
    this.name,
  });

  @override
  List<Object> get props => [email, password, nickname, name ?? ''];
}

/// Evento para cerrar la sesión
class LogoutRequested extends AuthEvent {}
