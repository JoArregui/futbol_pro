import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/features/auth/domain/repositories/auth_repository.dart';
import 'package:futbol_pro/features/auth/domain/usecases/login_user.dart';
import 'package:futbol_pro/features/auth/domain/usecases/register_user.dart';
import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/player.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockLoginUser extends Mock implements LoginUser {}
class MockRegisterUser extends Mock implements RegisterUser {}

void main() {
  late MockAuthRepository mockRepo;
  late MockLoginUser mockLogin;
  late MockRegisterUser mockRegister;

  const tPlayer = Player(
    id: 'uid-123',
    name: 'Test User',
    nickname: 'tester',
    profileImageUrl: '',
    rating: 4.5,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    mockLogin = MockLoginUser();
    mockRegister = MockRegisterUser();
    registerFallbackValue(const LoginParams(email: 'a@a.com', password: '123'));
    registerFallbackValue(const RegisterParams(email: 'a@a.com', password: '123', nickname: 'nick'));
  });

  AuthBloc buildBloc() => AuthBloc(
        loginUser: mockLogin,
        registerUser: mockRegister,
        repository: mockRepo,
      );

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthUnauthenticated] cuando AppStarted no hay sesión',
      build: () {
        when(() => mockRepo.getAuthenticatedPlayer())
            .thenAnswer((_) async => const Left(CacheFailure('no session')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando AppStarted hay sesión',
      build: () {
        when(() => mockRepo.getAuthenticatedPlayer())
            .thenAnswer((_) async => const Right(tPlayer));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
      verify: (bloc) => expect((bloc.state as AuthAuthenticated).userId, 'uid-123'),
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested éxito → AuthAuthenticated',
      build: () {
        when(() => mockLogin(any())).thenAnswer((_) async => const Right(tPlayer));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@test.com', password: 'pass123')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested fallo → AuthError',
      build: () {
        when(() => mockLogin(any())).thenAnswer((_) async => const Left(ServerFailure('Credenciales inválidas')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'bad@test.com', password: 'wrong')),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'RegisterRequested éxito → AuthAuthenticated',
      build: () {
        when(() => mockRegister(any())).thenAnswer((_) async => const Right(tPlayer));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RegisterRequested(email: 'new@test.com', password: 'pass123', nickname: 'newbie')),
      expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'LogoutRequested éxito → AuthUnauthenticated',
      build: () {
        when(() => mockRepo.logout()).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });
}
