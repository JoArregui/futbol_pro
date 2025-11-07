import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart'; // Asegúrate de que esta importación sea correcta

class AuthInitializer extends StatefulWidget {
  const AuthInitializer({super.key});

  @override
  State<AuthInitializer> createState() => _AuthInitializerState();
}

class _AuthInitializerState extends State<AuthInitializer> {
  @override
  void initState() {
    super.initState();
    // 🟢 EL PASO CRÍTICO: DISPARAR EL EVENTO AL INICIAR EL WIDGET
    // Esto fuerza al BLoC a cambiar de AuthInitial a AuthLoading/AuthUnauthenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AppStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar el estado del BLoC es opcional aquí, 
    // ya que el GoRouter.redirect hace el trabajo.
    // Solo necesitamos que muestre la UI de carga.
    return const Scaffold(
      backgroundColor: Color(0xFF008080), // Color de ejemplo, usa tu tema
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono o logo
            Icon(
              Icons.sports_soccer, 
              size: 80, 
              color: Colors.white,
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Verificando sesión...', 
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}