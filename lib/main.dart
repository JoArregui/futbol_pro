import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- IMPORTANTE: Importar firebase_core
import 'core/injection_container.dart' as di;
import 'core/services/notification_service.dart';
import 'routes/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
// Asegúrate de que este archivo exista después de correr flutterfire configure
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ==========================================================
  // 1. CRÍTICO: Inicializar Firebase primero
  // Esto debe suceder antes de cualquier dependencia (di.init()) 
  // que intente usar Firebase, como NotificationService.
  // ==========================================================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Si la inicialización falla (ej. falta google-services.json), imprime el error
    print('Firebase Initialization Error: $e');
  }

  // 2. Inicializa todas las dependencias (GetIt) - Ahora pueden usar Firebase
  di.init(); 

  // 3. Inicializa servicios Core esenciales (si es necesario)
  // Nota: Si initializeNotifications() usa FirebaseMessaging, la línea 
  // 1 debe ir antes de di.init() Y antes de esta línea.
  try {
    await di.sl<NotificationService>().initializeNotifications(); 
  } catch (e) {
    print('Notification Service Initialization Error (likely Firebase setup related): $e');
  }
  
  // 4. Dispara la verificación de autenticación inicial
  di.sl<AuthBloc>().add(AppStarted()); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 5. Provee el AuthBloc a todo el árbol de widgets
    return BlocProvider<AuthBloc>.value(
      value: di.sl<AuthBloc>(),
      child: Builder(
        builder: (context) {
          // 6. Usa el AuthBloc para configurar el GoRouter
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
          // Las rutas deben ser definidas en AppRoutes
          if (index == 0) context.go('/home'); // Asumo la ruta /home
          if (index == 1) context.go('/standings'); // Asumo la ruta /standings
          if (index == 2) context.go('/fields'); // Asumo la ruta /fields
        },
      ),
    );
  }
}
