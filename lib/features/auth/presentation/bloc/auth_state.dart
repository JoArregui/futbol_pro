part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
const AuthState();
@override
List<Object> get props => [];
}

class AuthInitial extends AuthState { const AuthInitial(); }

class AuthLoading extends AuthState { const AuthLoading(); }

class AuthAuthenticated extends AuthState {
final Player player;
const AuthAuthenticated({required this.player});
@override
List<Object> get props => [player];
}

class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }

class AuthError extends AuthState {
final String message;
const AuthError({required this.message});
@override
List<Object> get props => [message];
}