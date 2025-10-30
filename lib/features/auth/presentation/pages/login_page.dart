import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // === MODO DE PRUEBA ===
  final bool _isDemoMode = true; // Cambiar a false cuando conectes API/BD

  @override
  void initState() {
    super.initState();
    
    // === VALORES DE PRUEBA INICIALIZADOS AQUÍ ===
    if (_isDemoMode) {
      _emailController.text = 'demo@futbolpro.com';
      _passwordController.text = 'demo123';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      // === MODO DEMO: Bypass de autenticación ===
      if (_isDemoMode) {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        
        // Usuario de prueba hardcodeado
        if (email == 'demo@futbolpro.com' && password == 'demo123') {
          // Simular login exitoso sin llamar a la API
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Login exitoso! (Modo Demo)'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navegar directamente a home sin pasar por el Bloc
          context.go(AppRoutes.home);
          return;
        } else {
          // Credenciales incorrectas en modo demo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credenciales incorrectas. Use: demo@futbolpro.com / demo123'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // === MODO PRODUCCIÓN: Login real con Bloc ===
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isDemoMode ? 'Iniciar Sesión (Demo)' : 'Iniciar Sesión'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
          // La redirección a /home se maneja en AppRouter al pasar a AuthAuthenticated
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // === BANNER DE MODO DEMO ===
                    if (_isDemoMode)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade800),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Modo Demo\nUsuario: demo@futbolpro.com\nContraseña: demo123',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa tu email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa tu contraseña.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 24),
                    
                    const Divider(),
                    const SizedBox(height: 16),

                    // Register Prompt
                    Text(
                      '¿Aún no tienes una cuenta?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),

                    // Register Button
                    TextButton(
                      onPressed: isLoading ? null : () {
                        // Navegar a la ruta de registro
                        context.go(AppRoutes.register); 
                      },
                      child: const Text('Regístrate aquí'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}