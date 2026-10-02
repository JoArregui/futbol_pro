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

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String password;
  const ResetPasswordRequested({required this.token, required this.password});

  @override
  List<Object> get props => [token, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class BiometricUnlockRequested extends AuthEvent {
  const BiometricUnlockRequested();
}

class BiometricEnrollmentRequested extends AuthEvent {
  final bool enabled;
  const BiometricEnrollmentRequested(this.enabled);
}
