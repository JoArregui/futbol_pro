import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final AuthRepository repository;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
    required this.repository,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.getAuthenticatedPlayer();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (player) => emit(AuthAuthenticated(player.id)),
    );
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    if (state is AuthLoading) return;
    emit(AuthLoading());
    final result = await loginUser(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthAuthenticated(player.id)),
    );
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    if (state is AuthLoading) return;
    emit(AuthLoading());
    final result = await registerUser(
      RegisterParams(
        email: event.email,
        password: event.password,
        nickname: event.nickname,
        name: event.name,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthAuthenticated(player.id)),
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.logout();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
