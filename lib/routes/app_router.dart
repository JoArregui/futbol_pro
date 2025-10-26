import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Importa tus BLoCs y Páginas de cada módulo
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart'; // Crearemos esta página
import '../features/league_management/presentation/pages/standings_page.dart';
import '../features/match_scheduling/presentation/pages/match_list_page.dart'; // Crearemos esta página
import '../features/field_management/presentation/pages/field_search_page.dart';

// Nombres de rutas estáticos para evitar errores de tipeo
class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const standings = '/standings';
  static const schedule = '/schedule';
  static const fields = '/fields';
}

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    // Clave para gestionar el estado de los campos de texto durante la redirección
    initialLocation: AppRoutes.home,
    
    // ===============================================
    // LÓGICA DE REDIRECCIÓN CENTRAL
    // ===============================================
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      
      // 1. Si la aplicación recién inicia y el estado es Inicial, esperamos.
      if (authState is AuthInitial) return null; 

      // 2. Si el usuario está autenticado (logueado)
      if (authState is AuthAuthenticated) {
        // Si está logueado y va a la pantalla de login, lo redirigimos a la Home.
        return isLoggingIn ? AppRoutes.home : null; 
      }

      // 3. Si el usuario NO está autenticado
      if (authState is AuthUnauthenticated || authState is AuthError) {
        // Si no está logueado y NO está en la página de login, lo redirigimos al Login.
        return isLoggingIn ? null : AppRoutes.login; 
      }
      
      // Permitir la navegación normal en cualquier otro caso
      return null;
    },
    
    // Escucha los cambios en el AuthBloc para forzar la revisión de redirección
    refreshListenable: GoRouterRefreshStream(authBloc.stream),

    // ===============================================
    // DEFINICIÓN DE RUTAS
    // ===============================================
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      // La Home Page debe ser un ShellRoute para incluir la barra de navegación (TabBar/BottomNavBar)
      ShellRoute(
        builder: (context, state, child) {
          // Usar una Scaffold que contenga la BottomNavigationBar y el 'child' de la ruta actual
          return MainScaffold(child: child); 
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const MatchListPage(), // Pantalla principal de partidos
          ),
          GoRoute(
            path: AppRoutes.standings,
            builder: (context, state) => const StandingsPage(currentLeagueId: 'liga-actual'),
          ),
          GoRoute(
            path: AppRoutes.fields,
            builder: (context, state) => const FieldSearchPage(),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            builder: (context, state) => const MatchListPage(),
          ),
          // ... Otras rutas de ligas, perfiles, etc.
        ],
      ),
    ],
  );
}