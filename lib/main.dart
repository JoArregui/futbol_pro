import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/injection_container.dart' as di;
import 'core/services/notification_service.dart';
import 'routes/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializa todas las dependencias (GetIt)
  di.init(); 

  // 2. Inicializa servicios Core esenciales (si no lo haces en init())
  await di.sl<NotificationService>().initializeNotifications(); 
  
  // 3. Dispara la verificación de autenticación inicial
  di.sl<AuthBloc>().add(AppStarted()); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Provee el AuthBloc a todo el árbol de widgets
    return BlocProvider<AuthBloc>.value(
      value: di.sl<AuthBloc>(),
      child: Builder(
        builder: (context) {
          // 5. Usa el AuthBloc para configurar el GoRouter
          final router = AppRouter(context.read<AuthBloc>());
          
          return MaterialApp.router(
            title: 'Liga Semiprofesional App',
            theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
            routerConfig: router.router, // Aquí se inyecta el router con su lógica de redirección
          );
        }
      ),
    );
  }
}

// Widget auxiliar para manejar el Scaffold principal (BottomNavBar)
class MainScaffold extends StatelessWidget {
  final Widget child;
  
  const MainScaffold({super.key, required this.child});

  // La lógica para la navegación debe estar aquí, usando context.go(AppRoutes.xyz)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        // ... Lógica de navegación a las rutas home, standings, fields ...
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Partidos'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Clasificación'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Campos'),
        ],
        onTap: (index) {
          // Lógica simple de navegación con GoRouter
          if (index == 0) context.go(AppRoutes.home);
          if (index == 1) context.go(AppRoutes.standings);
          if (index == 2) context.go(AppRoutes.fields);
        },
      ),
    );
  }
}