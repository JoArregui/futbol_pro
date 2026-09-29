part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String role;
  const AuthAuthenticated(this.userId, {this.role = 'player'});
  bool get isSuperAdmin => role == 'superadmin';
  @override
  List<Object> get props => [userId, role];
}

class AuthBiometricRequired extends AuthState {
  final String userId;
  final String role;
  const AuthBiometricRequired(this.userId, {this.role = 'player'});
  @override
  List<Object> get props => [userId, role];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}
