import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/routing/go_router_refresh_stream.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart'; 
import '../main.dart'; 
// Importación de las páginas de autenticación
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
// Importación de las constantes de ruta
import 'app_routes.dart'; // Aseguramos el import del Scaffold principal


/// Clase que gestiona la configuración de GoRouter y las rutas de la aplicación.
class AppRouter {
  final AuthBloc authBloc;
  late final GoRouter router;

  AppRouter(this.authBloc) {
    router = GoRouter(
      // Usamos el estado del AuthBloc para la redirección
      initialLocation: AppRoutes.initial, // Usar constante
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;

        // Rutas que no requieren autenticación
        final isAuthRoute = state.matchedLocation == AppRoutes.login || // Usar constante
                            state.matchedLocation == AppRoutes.register; // Usar constante

        // 1. Splash Screen / Inicialización
        if (authState is AuthInitial || authState is AuthLoading) {
          // Si estamos cargando, nos quedamos en la ruta actual o vamos al splash.
          return state.matchedLocation == AppRoutes.initial ? null : AppRoutes.initial; // Usar constante
        }

        // 2. Usuario No Autenticado (AuthUnauthenticated)
        if (authState is AuthUnauthenticated) {
          // Si ya está en la ruta de autenticación (login/register), no redirigir.
          return isAuthRoute ? null : AppRoutes.login; // Usar constante
        }

        // 3. Usuario Autenticado (AuthAuthenticated)
        if (authState is AuthAuthenticated) {
          // Si está autenticado e intenta ir a login/register o al splash, redirigir a la Home.
          if (isAuthRoute || state.matchedLocation == AppRoutes.initial) { // Usar constante
            return AppRoutes.home; // Usar constante
          }
        }
        
        // 4. No hay redirección, ir a la ruta solicitada
        return null;
      },
      
      routes: <RouteBase>[
        // Ruta de Inicialización (Splash)
        GoRoute(
          path: AppRoutes.initial, // Usar constante
          builder: (context, state) => const AuthInitializer(),
        ),

        // Rutas de Autenticación
        GoRoute(
          path: AppRoutes.login, // Usar constante
          builder: (context, state) => const LoginPage(), // REEMPLAZADO por LoginPage
        ),
        GoRoute(
          path: AppRoutes.register, // Usar constante
          builder: (context, state) => const RegisterPage(), // REEMPLAZADO por RegisterPage
        ),

        // Rutas con Bottom Navigation Bar (MainScaffold)
        ShellRoute(
          // Utilizamos MainScaffold para envolver las rutas principales
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.home, // Usar constante
              builder: (context, state) => const Placeholder(child: Center(child: Text('Home - Partidos'))),
            ),
            GoRoute(
              path: AppRoutes.standings, // Usar constante
              builder: (context, state) => const Placeholder(child: Center(child: Text('Liga - Clasificación'))),
            ),
            GoRoute(
              path: AppRoutes.fields, // Usar constante
              builder: (context, state) => const Placeholder(child: Center(child: Text('Campos'))),
            ),
            GoRoute(
              path: AppRoutes.profile, // Usar constante
              builder: (context, state) => const Placeholder(child: Center(child: Text('Perfil de Usuario'))),
            ),
          ],
        ),
      ],
    );
  }
}
