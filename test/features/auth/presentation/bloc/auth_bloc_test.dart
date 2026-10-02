import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/features/auth/domain/repositories/auth_repository.dart';
import 'package:futbol_pro/features/auth/domain/usecases/login_user.dart';
import 'package:futbol_pro/features/auth/domain/usecases/register_user.dart';
import 'package:futbol_pro/features/auth/domain/usecases/forgot_password.dart';
import 'package:futbol_pro/features/auth/domain/usecases/reset_password.dart';
import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:futbol_pro/features/match_scheduling/domain/entities/player.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLoginUser extends Mock implements LoginUser {}

class MockRegisterUser extends Mock implements RegisterUser {}

class MockForgotPassword extends Mock implements ForgotPassword {}

class MockResetPassword extends Mock implements ResetPassword {}

void main() {
  late MockAuthRepository mockRepo;
  late MockLoginUser mockLogin;
  late MockRegisterUser mockRegister;
  late MockForgotPassword mockForgot;
  late MockResetPassword mockReset;

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
    mockForgot = MockForgotPassword();
    mockReset = MockResetPassword();
    registerFallbackValue(const LoginParams(email: 'a@a.com', password: '123'));
    registerFallbackValue(
      const RegisterParams(email: 'a@a.com', password: '123', nickname: 'nick'),
    );
    registerFallbackValue(const ForgotPasswordParams(email: 'a@a.com'));
    registerFallbackValue(const ResetPasswordParams(token: 'token', password: '12345678'));
    when(() => mockRepo.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => mockRepo.setBiometricEnabled(any())).thenAnswer((_) async {});
  });

  AuthBloc buildBloc() => AuthBloc(
    loginUser: mockLogin,
    registerUser: mockRegister,
    forgotPassword: mockForgot,
    resetPassword: mockReset,
    repository: mockRepo,
  );

  group('AuthBloc', () {
    test('AppStarted sin sesión -> AuthUnauthenticated', () async {
      when(
        () => mockRepo.getAuthenticatedPlayer(),
      ).thenAnswer((_) async => const Left(CacheFailure('no session')));
      final bloc = buildBloc();
      bloc.add(const AppStarted());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
      await bloc.close();
    });
    test('AppStarted con sesión -> AuthAuthenticated', () async {
      when(
        () => mockRepo.getAuthenticatedPlayer(),
      ).thenAnswer((_) async => const Right(tPlayer));
      final bloc = buildBloc();
      bloc.add(const AppStarted());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
      expect((bloc.state as AuthAuthenticated).userId, 'uid-123');
      await bloc.close();
    });
    test('Login éxito -> AuthAuthenticated', () async {
      when(
        () => mockLogin(any()),
      ).thenAnswer((_) async => const Right(tPlayer));
      final bloc = buildBloc();
      bloc.add(
        const LoginRequested(email: 'test@test.com', password: 'pass123'),
      );
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
      await bloc.close();
    });
    test('Login fallo -> AuthError', () async {
      when(() => mockLogin(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Credenciales inválidas')),
      );
      final bloc = buildBloc();
      bloc.add(const LoginRequested(email: 'bad@test.com', password: 'wrong'));
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );
      await bloc.close();
    });
    test('Register éxito -> AuthAuthenticated', () async {
      when(
        () => mockRegister(any()),
      ).thenAnswer((_) async => const Right(tPlayer));
      final bloc = buildBloc();
      bloc.add(
        const RegisterRequested(
          email: 'new@test.com',
          password: 'pass123',
          nickname: 'newbie',
        ),
      );
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );
      await bloc.close();
    });
    test('Logout éxito -> AuthUnauthenticated', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async => const Right(null));
      final bloc = buildBloc();
      bloc.add(const LogoutRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );
      await bloc.close();
    });
  });
}
