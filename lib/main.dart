import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'core/injection_container.dart' as di;
import 'core/services/notification_service.dart';
import 'routes/app_router.dart'; // ¡Asegúrate de que este archivo exista!
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar Firebase primero
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Firebase Initialization Error: $e');
  }

  // 2. Inicializa todas las dependencias (GetIt)
  // Se asume que di.init() inicializa sl<AuthBloc>()
  di.init(); 

  // 3. Inicializa servicios Core esenciales
  try {
    await di.sl<NotificationService>().initializeNotifications(); 
    print('✅ NotificationService inicializado');
  } catch (e) {
    print('❌ Notification Service Initialization Error: $e');
  }
  
  // 4. ⚡ CRÍTICO: Disparar verificación de sesión inicial
  di.sl<AuthBloc>().add(AppStarted()); 
  print('🔄 Verificación de sesión iniciada');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: di.sl<AuthBloc>(),
      child: Builder(
        builder: (context) {
          // Inicializa AppRouter (requiere 'routes/app_router.dart' disponible)
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
        }
      ),
    );
  }
}

// ==========================================================
// Widget auxiliar para manejar el Scaffold principal (BottomNavBar)
// ==========================================================
class MainScaffold extends StatelessWidget {
  final Widget child;
  
  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    // Nota: Usar GoRouter.of(context).routerDelegate.currentConfiguration.uri.path 
    // es más moderno, pero matches.last.matchedLocation funciona para esta estructura.
    final matches = GoRouter.of(context).routerDelegate.currentConfiguration.matches;
    final String location = matches.last.matchedLocation;
    
    // Calcula el índice basado en la ruta actual
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/standings')) return 1;
    if (location.startsWith('/fields')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // Default a la pestaña de Partidos
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/standings');
        break;
      case 2:
        context.go('/fields');
        break;
      case 3: 
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        // Los ítems de la barra de navegación.
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), 
            label: 'Partidos'
          ),
          BottomNavigationBarItem( 
            icon: Icon(Icons.emoji_events), 
            label: 'Liga' 
          ),
          BottomNavigationBarItem( 
            icon: Icon(Icons.location_on), 
            label: 'Campos'
          ),
          BottomNavigationBarItem( 
            icon: Icon(Icons.person), 
            label: 'Perfil'
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// Widget de Inicialización (Splash Screen)
// ==========================================================
class AuthInitializer extends StatelessWidget {
  const AuthInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer, 
              size: 100, 
              color: Colors.white
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Verificando sesión...',
              style: TextStyle(
                fontSize: 18, 
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
