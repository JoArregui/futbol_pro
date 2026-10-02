import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'firebase_options.dart';

// Injection Container
import 'core/injection_container.dart' as di;

// Services
import 'core/services/notification_service.dart';
import 'core/services/socket_service.dart';

// Routing & theme
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

// Features
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/match_scheduling/presentation/bloc/match_bloc.dart';
import 'features/field_management/presentation/bloc/field_bloc.dart';
import 'features/league_management/presentation/bloc/league_bloc.dart';

/// DSN de Sentry (compile-time). Sin DSN no se envía nada:
/// `flutter run --dart-define=SENTRY_DSN=https://...`
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de datos de localización para formateo de fechas
  await initializeDateFormatting('es', null);

  debugPrint(
    '⚙️ ${AppConfig.appName} | flavor=${AppConfig.flavor.name} \vert{} api=${AppConfig.apiUrl()}',
  );

  // Reporte global de errores: siempre a consola, a Sentry solo con DSN.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (_sentryDsn.isNotEmpty) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('❌ Unhandled async: $error');
    if (_sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stack);
    }
    return true;
  };

  try {
    debugPrint('🔥 Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase inicializado correctamente');

    debugPrint('🔧 Inicializando dependency injection...');
    await di.init();
    debugPrint('✅ Dependency injection inicializado');

    debugPrint('🔔 Inicializando NotificationService...');
    await di.sl<NotificationService>().initialize();
    debugPrint('✅ NotificationService inicializado');

    // ✅ CORRECCIÓN: Instanciamos el AuthBloc y el AppRouter aquí para pasarlos a MyApp
    final authBloc = di.sl<AuthBloc>();
    final appRouter = AppRouter(authBloc);

    runApp(MyApp(authBloc: authBloc, appRouter: appRouter));
  } catch (e, stackTrace) {
    debugPrint('❌ Error durante la inicialización: $e');
    debugPrint('Stack trace: $stackTrace');
    if (_sentryDsn.isNotEmpty) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }

    // Mostrar error en pantalla
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al inicializar la aplicación',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  if (_sentryDsn.isEmpty) {
    return _bootstrap();
  }
  await SentryFlutter.init((options) {
    options.dsn = _sentryDsn;
    options.tracesSampleRate = 0.2;
  }, appRunner: _bootstrap);
}

class MyApp extends StatelessWidget {
  // ✅ Añadimos las dependencias como argumentos
  final AuthBloc authBloc;
  final AppRouter appRouter;

  const MyApp({super.key, required this.authBloc, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ✅ Usamos la instancia de BLoC creada en main()
        BlocProvider<AuthBloc>.value(value: authBloc),

        // El resto de BLoCs se obtienen del Service Locator (sl)
        BlocProvider<ProfileBloc>(create: (_) => di.sl<ProfileBloc>()),
        BlocProvider<ChatBloc>(create: (_) => di.sl<ChatBloc>()),
        BlocProvider<MatchBloc>(create: (_) => di.sl<MatchBloc>()),
        BlocProvider<FieldBloc>(create: (_) => di.sl<FieldBloc>()),
        BlocProvider<LeagueBloc>(create: (_) => di.sl<LeagueBloc>()),
      ],
      // Un solo MaterialApp.router siempre. El splash es GoRoute('/splash')
      // vía redirect; sin Stack overlay ni reconstrucciones del Navigator.
      // El router es `late final` estable: rebuilds del widget no pierden estado.
      // Wiring socket↔sesión: (re)conecta al autenticar, desconecta al salir.
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            try {
              context.read<ChatBloc>().reconnectSocket();
            } catch (_) {}
          } else if (state is AuthUnauthenticated) {
            try {
              di.sl<SocketService>().disconnect();
            } catch (_) {}
          }
        },
        child: MaterialApp.router(
          title: 'Futbol Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: appRouter.router,
        ),
      ),
    );
  }
}
