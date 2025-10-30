import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../match_scheduling/domain/entities/player.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
final LoginUser loginUser;
final RegisterUser registerUser;
final AuthRepository repository;
static const bool isDemoMode = true;

AuthBloc({
required this.loginUser, 
required this.registerUser,
required this.repository,
}) : super(const AuthInitial()) {
on<AppStarted>(_onAppStarted);
on<LoginRequested>(_onLoginRequested);
on<RegisterRequested>(_onRegisterRequested);
on<LogoutRequested>(_onLogoutRequested);
}

Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
if (isDemoMode) {
emit(const AuthUnauthenticated());
return;
}
final failureOrPlayer = await repository.getAuthenticatedPlayer();
failureOrPlayer.fold(
(_) => emit(const AuthUnauthenticated()),
(player) {
emit(AuthAuthenticated(player: player));
},
);
}

Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
emit(const AuthLoading());

if (isDemoMode && event.email == 'demo@futbolpro.com' && event.password == 'demo123') {
await Future.delayed(const Duration(milliseconds: 800));
final demoPlayer = const Player( 
id: 'demo-player-123',
nickname: 'DemoPlayer',
name: 'Usuario Demo',
profileImageUrl: 'https://i.pravatar.cc/150?u=demoplayer',
rating: 1500.0,
);
emit(AuthAuthenticated(player: demoPlayer));
return;
}

if (isDemoMode) {
await Future.delayed(const Duration(milliseconds: 500));
emit(const AuthError(
message: 'Credenciales incorrectas.\nUsa: demo@futbolpro.com / demo123'
));
return;
}

final failureOrPlayer = await loginUser(
LoginParams(email: event.email, password: event.password),
);
failureOrPlayer.fold(
(failure) => emit(AuthError(message: failure.errorMessage)),
(player) => emit(AuthAuthenticated(player: player)),
);
}

Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
emit(const AuthLoading());

if (isDemoMode) {
await Future.delayed(const Duration(milliseconds: 1000));
final demoPlayer = Player(
id: 'demo-player-${DateTime.now().millisecondsSinceEpoch}',
nickname: event.nickname,
name: 'Usuario Registrado', 
profileImageUrl: 'https://i.pravatar.cc/150?u=${event.email}',
rating: 1000.0,
);
emit(AuthAuthenticated(player: demoPlayer));
return;
}

final failureOrPlayer = await registerUser(
RegisterParams(
email: event.email, 
password: event.password, 
nickname: event.nickname,
name: event.name ?? '',
),
);
failureOrPlayer.fold(
(failure) => emit(AuthError(message: failure.errorMessage)),
(player) => emit(AuthAuthenticated(player: player)),
);
}

Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
emit(const AuthLoading()); 
if (isDemoMode) {
await Future.delayed(const Duration(milliseconds: 300));
emit(const AuthUnauthenticated());
return;
}
final failureOrVoid = await repository.logout();
failureOrVoid.fold(
(failure) => emit(AuthError(message: failure.errorMessage)),
(_) => emit(const AuthUnauthenticated()),
);
}
}