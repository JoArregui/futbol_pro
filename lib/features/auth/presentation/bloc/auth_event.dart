part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  // CORREGIDO: Usamos List<Object?> para permitir que las subclases incluyan propiedades opcionales (como 'name').
  List<Object?> get props => const [];
}

/// Disparado al iniciar la aplicación para verificar la sesión.
class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Disparado para iniciar sesión.
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  
  @override
  List<Object> get props => [email, password];
}

/// Disparado para registrar un nuevo usuario.
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String nickname;
  final String? name;
  
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.nickname,
    this.name,
  });
  
  @override
  // Ahora es compatible con el tipo de retorno de la clase base (List<Object?>).
  List<Object?> get props => [email, password, nickname, name];
}

/// Disparado para cerrar la sesión.
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}