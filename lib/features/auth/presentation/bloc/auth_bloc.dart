import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../match_scheduling/domain/entities/player.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart'; // ✅ Importamos el nuevo Use Case
import '../../domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser; // ✅ NUEVO: Use Case para el registro
  final AuthRepository
      repository; // Necesitamos el repo para getAuthenticatedPlayer y logout

  AuthBloc({
    required this.loginUser, 
    required this.registerUser, // ✅ Lo hacemos requerido en el constructor
    required this.repository,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested); // ✅ NUEVO: Manejador para el registro
    on<LogoutRequested>(_onLogoutRequested);
  }

  // Verifica el estado de autenticación al inicio
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final failureOrPlayer = await repository.getAuthenticatedPlayer();

    failureOrPlayer.fold(
      (_) => emit(AuthUnauthenticated()), // Si falla o no hay token
      (player) {
        emit(AuthAuthenticated(player: player));
        // Aquí podrías disparar la suscripción a notificaciones
        // sl<SubscribeToNotifications>().call(params...);
      },
    );
  }

  // Maneja la solicitud de Login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final failureOrPlayer = await loginUser(
      LoginParams(email: event.email, password: event.password),
    );

    failureOrPlayer.fold(
      (failure) => emit(AuthError(message: failure.errorMessage)),
      (player) => emit(AuthAuthenticated(player: player)),
    );
  }

  // ✅ NUEVO: Maneja la solicitud de Registro
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final failureOrPlayer = await registerUser(
      RegisterParams(
        email: event.email, 
        password: event.password, 
        nickname: event.nickname,
        name: event.name, // El nombre es opcional
      ),
    );

    failureOrPlayer.fold(
      (failure) => emit(AuthError(message: failure.errorMessage)),
      (player) => emit(AuthAuthenticated(player: player)),
    );
  }


  // Maneja la solicitud de Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final failureOrVoid = await repository.logout();

    failureOrVoid.fold(
      (failure) => emit(AuthError(message: failure.errorMessage)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
