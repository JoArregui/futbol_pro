import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class AuthInitializer extends StatefulWidget {
  const AuthInitializer({super.key});

  @override
  State<AuthInitializer> createState() => _AuthInitializerState();
}

class _AuthInitializerState extends State<AuthInitializer> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AppStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF008080),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
