import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/injection_container.dart' as di;
import 'core/services/notification_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase primero
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Firebase Initialization Error: $e');
  }

  di.init();

  try {
    await di.sl<NotificationService>().initializeNotifications();
    print('✅ NotificationService inicializado');
  } catch (e) {
    print('❌ Notification Service Initialization Error: $e');
  }

  di.sl<AuthBloc>().add(const AppStarted());
  print('🔄 Verificación de sesión iniciada');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 1. AuthBloc
        BlocProvider<AuthBloc>.value(
          value: di.sl<AuthBloc>(),
        ),
        // 2. ChatBloc
        BlocProvider<ChatBloc>(
          create: (context) =>
              di.sl<ChatBloc>()..add(ChatRoomsSubscriptionRequested()),
        ),
        // 3. ProfileBloc 
        BlocProvider<ProfileBloc>(
          create: (context) => di.sl<ProfileBloc>(),
        ),
      ],
      child: Builder(builder: (context) {
        final router = AppRouter(context.read<AuthBloc>());

        return MaterialApp.router(
          title: 'Liga Semiprofesional App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          ),
          routerConfig: router.router,
        );
      }),
    );
  }
}