import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/routing/go_router_refresh_stream.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/widgets/auth_initializer_widget.dart';
import '../presentation/widgets/main_scaffold.dart';
import 'app_routes.dart';

/// Clase que gestiona la configuración de GoRouter y las rutas de la aplicación.
class AppRouter {
  final AuthBloc authBloc;
  late final GoRouter router;

  AppRouter(this.authBloc) {
    router = GoRouter(
      initialLocation: AppRoutes.initial,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;

        // Rutas públicas
        final isAuthRoute = state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register;

        // 1. Splash Screen / Inicialización (AuthInitial o AuthLoading)
        if (authState is AuthInitial || authState is AuthLoading) {
          return state.matchedLocation == AppRoutes.initial
              ? null
              : AppRoutes.initial;
        }

        // 2. Usuario No Autenticado (AuthUnauthenticated)
        if (authState is AuthUnauthenticated) {
          // Si ya está en la ruta de autenticación (login/register), no redirigir.
          // Si está en cualquier otra ruta, redirigir a login.
          return isAuthRoute ? null : AppRoutes.login;
        }

        // 3. Usuario Autenticado (AuthAuthenticated)
        if (authState is AuthAuthenticated) {
          // Si está autenticado e intenta ir a login/register o al splash, redirigir a la Home.
          if (isAuthRoute || state.matchedLocation == AppRoutes.initial) {
            return AppRoutes.home;
          }
        }

        // 4. No hay redirección, ir a la ruta solicitada
        return null;
      },
      routes: <RouteBase>[
        // Ruta de Inicialización (Splash)
        GoRoute(
          path: AppRoutes.initial,
          builder: (context, state) => const AuthInitializer(),
        ),

        // Rutas de Autenticación
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterPage(),
        ),

        // Rutas con Bottom Navigation Bar (MainScaffold)
        ShellRoute(
          // Utilizamos MainScaffold para envolver las rutas principales
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const Center(
                  child:
                      Text('Home - Partidos', style: TextStyle(fontSize: 24))),
            ),
            GoRoute(
              path: AppRoutes.standings,
              builder: (context, state) => const Center(
                  child: Text('Liga - Clasificación',
                      style: TextStyle(fontSize: 24))),
            ),
            GoRoute(
              path: AppRoutes.fields,
              builder: (context, state) => const Center(
                  child: Text('Campos', style: TextStyle(fontSize: 24))),
            ),
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const Center(
                  child: Text('Perfil de Usuario',
                      style: TextStyle(fontSize: 24))),
            ),
          ],
        ),
      ],
    );
  }
}
