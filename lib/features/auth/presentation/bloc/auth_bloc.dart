import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/biometric_auth_service.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final AuthRepository repository;
  final BiometricAuthService biometricService;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
    required this.repository,
    BiometricAuthService? biometricService,
  }) : biometricService = biometricService ?? BiometricAuthService(),
       super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<BiometricUnlockRequested>(_onBiometricUnlock);
    on<BiometricEnrollmentRequested>(_onBiometricEnroll);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await repository.getAuthenticatedPlayer();
    await result.fold(
      (failure) async => emit(AuthUnauthenticated()),
      (player) async {
        // Si el usuario activó biometría, exigir desbloqueo local.
        final enabled = await repository.isBiometricEnabled();
        if (enabled) {
          final available = await biometricService.isAvailable();
          if (available) {
            emit(AuthBiometricRequired(player.id, role: player.role));
            return;
          }
        }
        emit(AuthAuthenticated(player.id, role: player.role));
      },
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
      (player) => emit(AuthAuthenticated(player.id, role: player.role)),
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
      (player) => emit(AuthAuthenticated(player.id, role: player.role)),
    );
  }

  Future<void> _onBiometricUnlock(
      BiometricUnlockRequested event, Emitter<AuthState> emit) async {
    final current = state;
    String userId = '';
    String role = 'player';
    if (current is AuthBiometricRequired) {
      userId = current.userId;
      role = current.role;
    } else {
      final res = await repository.getAuthenticatedPlayer();
      final player = res.fold((_) => null, (p) => p);
      if (player == null) {
        emit(AuthUnauthenticated());
        return;
      }
      userId = player.id;
      role = player.role;
    }
    final ok = await biometricService.authenticate(
        reason: 'Desbloquea Futbol Pro con tu huella');
    if (ok) {
      emit(AuthAuthenticated(userId, role: role));
    } else {
      emit(AuthBiometricRequired(userId, role: role));
    }
  }

  Future<void> _onBiometricEnroll(
      BiometricEnrollmentRequested event, Emitter<AuthState> emit) async {
    if (event.enabled) {
      final ok = await biometricService.authenticate(
          reason: 'Activa el desbloqueo con huella');
      if (!ok) return;
    }
    await repository.setBiometricEnabled(event.enabled);
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
