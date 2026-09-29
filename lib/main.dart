import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'firebase_options.dart';

// Injection Container
import 'core/injection_container.dart' as di;
import 'core/injection_container.dart';

// Services
import 'core/services/notification_service.dart';

// Routing & Initializer
import 'routes/app_router.dart';
import 'features/auth/presentation/widgets/auth_initializer_widget.dart';

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

    debugPrint('🔔 Inicializando NotificationService...');
    final notificationService = NotificationServiceImpl();
    await notificationService.initialize();
    debugPrint('✅ NotificationService inicializado');

    debugPrint('🔧 Inicializando dependency injection...');
    await di.init();
    debugPrint('✅ Dependency injection inicializado');

    // ✅ CORRECCIÓN: Instanciamos el AuthBloc y el AppRouter aquí para pasarlos a MyApp
    final authBloc = sl<AuthBloc>();
    final appRouter = AppRouter(authBloc);

    runApp(MyApp(authBloc: authBloc, appRouter: appRouter));
  } catch (e, stackTrace) {
    debugPrint('❌ Error durante la inicialización: $e');
    debugPrint('Stack trace: $stackTrace');
    if (_sentryDsn.isNotEmpty) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }

    // Mostrar error en pantalla
    runApp(MaterialApp(
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
    ));
  }
}

void main() async {
  if (_sentryDsn.isEmpty) {
    return _bootstrap();
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 0.2;
    },
    appRunner: _bootstrap,
  );
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
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
        BlocProvider<ChatBloc>(create: (_) => sl<ChatBloc>()),
        BlocProvider<MatchBloc>(create: (_) => sl<MatchBloc>()),
        BlocProvider<FieldBloc>(create: (_) => sl<FieldBloc>()),
        BlocProvider<LeagueBloc>(create: (_) => sl<LeagueBloc>()),
      ],
      // 🚀 Lógica de enrutamiento basada en el estado inicial de AuthBloc
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Obtener el tema base del contexto
          final lightTheme = ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
          );
          final darkTheme = ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
          );
          
          // 1. Si el estado es AuthInitial, mostramos el SplashScreen
          if (state is AuthInitial) {
            // Usamos MaterialApp simple con la pantalla de inicialización
            return MaterialApp(
              title: 'Futbol Pro',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: ThemeMode.system,
              home: const AuthInitializer(), 
            );
          }
          
          // 2. Si el estado es conocido (Autenticado o No Autenticado), 
          // usamos MaterialApp.router. GoRouter activa el 'redirect' 
          // inmediatamente para llevar al usuario a la ruta correcta.
          return MaterialApp.router(
            title: 'Futbol Pro',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: appRouter.router, // ✅ Usamos GoRouter
          );
        },
      ),
    );
  }
}