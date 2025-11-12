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
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    if (state is AuthLoading || state is AuthAuthenticated) {
      return;
    }

    emit(AuthLoading());

    const String demoEmail = 'demo@futbolpro.com';
    const String demoPassword = 'demo123';

    if (event.email == demoEmail && event.password == demoPassword) {
      await Future.delayed(const Duration(milliseconds: 500));
      print('✅ Login de Demo exitoso. Emitiendo AuthAuthenticated.');
      emit(const AuthAuthenticated('demo-user-id-001'));
      return;
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AuthAuthenticated('prod-user-123'));
    } catch (e) {
      emit(AuthError('Fallo en el login: ${e.toString()}'));

      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    if (state is AuthLoading || state is AuthAuthenticated) {
      return;
    }

    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(const AuthAuthenticated('new-user-456'));
    } catch (e) {
      emit(AuthError('Fallo en el registro: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Fallo en el logout: ${e.toString()}'));
    }
  }
}
