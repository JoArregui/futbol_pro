import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:futbol_pro/routes/app_routes.dart';

import '../core/routing/go_router_refresh_stream.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/chat/presentation/pages/chat_list_page.dart';
import '../features/chat/presentation/pages/chat_room_page.dart';
import '../features/chat/presentation/pages/new_chat_page.dart';
import '../features/field_management/presentation/pages/field_search_page.dart';
import '../features/league_management/presentation/pages/standings_page.dart';
import '../features/league_management/presentation/pages/tournaments_page.dart';
import '../features/league_management/presentation/pages/league_detail_page.dart';
import '../features/main_page/presentation/pages/home_page.dart';
import '../features/match_scheduling/presentation/pages/create_match_page.dart';
import '../features/match_scheduling/presentation/pages/match_detail_page.dart';
import '../features/match_scheduling/presentation/pages/match_list_page.dart';
import '../features/admin/presentation/bloc/admin_bloc.dart';
import '../features/match_scheduling/presentation/bloc/match_detail_bloc.dart';
import '../features/admin/presentation/pages/admin_panel_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../presentation/widgets/main_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/injection_container.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    // Escucha el stream del AuthBloc para reevaluar las rutas
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
          final hideNavBar = state.matchedLocation.contains('room') ||
              state.matchedLocation.contains('match_detail') ||
              state.matchedLocation.contains('/chat/new');
          return MainScaffold(
            hideBottomBar: hideNavBar,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.matches,
            builder: (context, state) => const MatchListPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'matchNew',
                builder: (context, state) => const CreateMatchPage(),
              ),
              GoRoute(
                path: 'match_detail/:matchId',
                name: 'matchDetail',
                builder: (context, state) {
                  final matchId =
                      state.pathParameters['matchId'] ?? 'default_id';
                  return BlocProvider(
                    create: (_) => sl<MatchDetailBloc>(),
                    child: MatchDetailPage(matchId: matchId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.standings,
            builder: (context, state) => const StandingsPage(),
          ),
          GoRoute(
            path: AppRoutes.tournaments,
            builder: (context, state) => const TournamentsPage(),
            routes: [
              GoRoute(
                path: ':leagueId',
                name: 'leagueDetail',
                builder: (context, state) {
                  final leagueId =
                      state.pathParameters['leagueId'] ?? '';
                  final leagueName =
                      state.uri.queryParameters['name'] ?? 'Liga';
                  return LeagueDetailPage(
                      leagueId: leagueId, leagueName: leagueName);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.fields,
            builder: (context, state) => const FieldSearchPage(),
          ),
          GoRoute(
            path: AppRoutes.chat,
            builder: (context, state) => const ChatListPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'newChat',
                builder: (context, state) => const NewChatPage(),
              ),
              GoRoute(
                path: ':roomId',
                name: 'chatRoom',
                builder: (context, state) {
                  final roomId = state.pathParameters['roomId'] ?? 'unknown';
                  if (roomId == 'new') return const NewChatPage();
                  return ChatRoomPage(chatRoomId: roomId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.admin,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<AdminBloc>(),
              child: const AdminPanelPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
    ],
    // FUNCIÓN DE REDIRECCIÓN: maneja la lógica de autenticación
    // Nunca anónima: sin AuthAuthenticated no se entra a nada protegido.
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final needsBiometric = authState is AuthBiometricRequired;
      final loc = state.matchedLocation;
      final isLoggingInOrUp = loc == AppRoutes.login || loc == AppRoutes.register;

      if (needsBiometric) {
        // Con biometría pendiente, forzar al login (pantalla de huella).
        return isLoggingInOrUp ? null : AppRoutes.login;
      }

      if (isAuthenticated) {
        if (isLoggingInOrUp) return AppRoutes.home;
        // Guard superadmin (authState ya es AuthAuthenticated aquí)
        final role = authState.role;
        if (loc.startsWith(AppRoutes.admin) && role != 'superadmin') {
          return AppRoutes.home;
        }
        return null;
      } else {
        // Si NO estás autenticado y tratas de ir a una página protegida (que no es login/register), ve a login.
        return isLoggingInOrUp ? null : AppRoutes.login;
      }
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error de Navegación'),
        automaticallyImplyLeading: true,
      ),
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
}