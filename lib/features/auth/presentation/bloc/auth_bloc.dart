import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Dependencias de Dominio y Repositorio (ejemplos)
// Asegúrate de que estas rutas son correctas en tu proyecto
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/repositories/auth_repository.dart'; 

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // 1. Definición de las dependencias inyectadas
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final AuthRepository repository;

  // 2. Constructor corregido para aceptar los parámetros inyectados
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

  /// 🟢 CORRECCIÓN CLAVE: TRANSICIÓN TEMPORAL DE AuthInitial A AuthUnauthenticated
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // En una implementación real, aquí llamarías a repository.checkAuthStatus()
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthUnauthenticated()); // Forzar la transición a NO AUTENTICADO para el flujo de inicio
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  // El resto de la lógica para Login, Registro y Logout
  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // ⚠️ Uso del Caso de Uso inyectado:
      // final String userId = await loginUser(
      //   LoginParams(email: event.email, password: event.password),
      // );
      
      // Simulación temporal:
      await Future.delayed(const Duration(seconds: 1));
      emit(const AuthAuthenticated('prod-user-123'));
    } catch (e) {
      emit(AuthError('Fallo en el login: ${e.toString()}'));
      // Volvemos al estado no autenticado para permitir reintentos
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // ⚠️ Uso del Caso de Uso inyectado:
      // final String userId = await registerUser(
      //   RegisterParams(
      //     email: event.email,
      //     password: event.password,
      //     nickname: event.nickname,
      //     name: event.name,
      //   ),
      // );

      // Simulación temporal:
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
      // ⚠️ Uso del Repositorio inyectado:
      // await repository.logout();
      
      // Simulación temporal:
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Fallo en el logout: ${e.toString()}'));
    }
  }
}