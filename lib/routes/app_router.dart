import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:futbol_pro/routes/app_routes.dart';

import '../core/routing/go_router_refresh_stream.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/chat/presentation/pages/chat_list_page.dart';
import '../features/chat/presentation/pages/chat_room_page.dart';
import '../features/field_management/presentation/pages/field_search_page.dart';
import '../features/league_management/presentation/pages/standings_page.dart';
import '../features/main_page/presentation/pages/home_page.dart';
import '../features/match_scheduling/presentation/pages/match_detail_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../presentation/widgets/main_scaffold.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) {
        
          final hideNavBar = state.matchedLocation.contains('room') ||
              state.matchedLocation.contains('match_detail');
          return MainScaffold(
            hideBottomBar: hideNavBar,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
            routes: [
           
              GoRoute(
                path: 'match_detail/:matchId',
                name: 'matchDetail',
                builder: (context, state) {
                  final matchId =
                      state.pathParameters['matchId'] ?? 'default_id';
                  return MatchDetailPage(matchId: matchId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.standings,
            builder: (context, state) => const StandingsPage(
              currentLeagueId: 'default_league_id',
            ),
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
                path: ':roomId', 
                name: 'chatRoom',
                builder: (context, state) {
                  final roomId = state.pathParameters['roomId'] ?? 'unknown';
                  return ChatRoomPage(chatRoomId: roomId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
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
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoggingInOrUp =
          state.fullPath == AppRoutes.login || state.fullPath == AppRoutes.register;

      if (isAuthenticated) {
        return isLoggingInOrUp ? AppRoutes.home : null;
      } else {
        final isProtected = !isLoggingInOrUp;
        return isProtected ? AppRoutes.login : null;
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