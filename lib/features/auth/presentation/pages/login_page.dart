import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/widgets/connection_banner.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
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
        centerTitle: true,
        title: const Text('Iniciar Sesión'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            final isConn = state.message.contains('No se pudo conectar') || state.message.contains('Timeout');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isConn ? '${state.message}\n→ Verifica server npm run dev' : 'Error al iniciar sesión: ${state.message}'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 5),
              ),
            );
          }

          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inicio de sesión exitoso.')),
            );
            // La navegación a AppRoutes.home la maneja el 'redirect' del GoRouter.
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            // Desbloqueo biométrico obligatorio si está activado
            if (authState is AuthBiometricRequired) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fingerprint,
                          size: 80, color: Colors.teal),
                      const SizedBox(height: 16),
                      const Text('Sesión protegida',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Usa tu huella para entrar. Nunca entramos de forma anónima.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(const BiometricUnlockRequested()),
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Desbloquear con huella'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(const LogoutRequested()),
                        child: const Text('Usar otra cuenta'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return _loginForm(context);
          },
        ),
      ),
    );
  }

  Widget _loginForm(BuildContext context) {
    return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const ConnectionBanner(),
                  const SizedBox(height: 8),
                  const Text(
                    'Acceso seguro con contraseña. Opcional: activa la huella en tu perfil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return 'Ingresa un email válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                        return 'La contraseña es obligatoria.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _onLoginPressed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Iniciar Sesión',
                                style: TextStyle(fontSize: 18)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // ✅ CORRECCIÓN: Usar push() o replace() en lugar de go()
                      // para navegar a una ruta hermana (registro) desde el login.
                      context.push(AppRoutes.register);
                    },
                    child: const Text('Crear una cuenta nueva'),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}