part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

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
  List<Object?> get props => [email, password, nickname, name];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
