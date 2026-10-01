import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
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
  bool _obscure = true;

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
      body: HeroBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
            if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('¡Bienvenido de vuelta, crack! ⚽')),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthBiometricRequired) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientLime,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fingerprint,
                                size: 44, color: Colors.black),
                          ),
                          const SizedBox(height: 16),
                          const Text('Desbloqueo rápido con huella',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          const Text(
                            'La activaste tú en tu Perfil. Es opcional: evita reescribir la contraseña al volver. El primer login siempre fue con email + contraseña y puedes desactivarla cuando quieras.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textDim),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            label: 'Desbloquear con huella',
                            icon: Icons.fingerprint,
                            onPressed: () => context
                                .read<AuthBloc>()
                                .add(const BiometricUnlockRequested()),
                          ),
                          AppButton.ghost(
                            label: 'Usar otra cuenta',
                            onPressed: () => context
                                .read<AuthBloc>()
                                .add(const LogoutRequested()),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return _loginForm(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _loginForm(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientLime,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lime.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sports_soccer,
                      color: Colors.black, size: 42),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('FUTBOL PRO',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ),
              const Center(
                child: Text('Tu club, tus partidos, tu nivel.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 14)),
              ),
              const SizedBox(height: 22),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Iniciar sesión',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Acceso seguro con contraseña.',
                        style:
                            TextStyle(color: AppColors.textDim, fontSize: 13)),
                    const SizedBox(height: 16),
                    const ConnectionBanner(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'tu@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Ingresa un email válido.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'La contraseña es obligatoria.'
                          : null,
                      onFieldSubmitted: (_) => _onLoginPressed(),
                    ),
                    const SizedBox(height: 18),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return AppButton(
                          label: 'Iniciar Sesión',
                          icon: Icons.login_rounded,
                          loading: state is AuthLoading,
                          onPressed:
                              state is AuthLoading ? null : _onLoginPressed,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    AppButton.ghost(
                      label: 'Crear una cuenta nueva',
                      icon: Icons.person_add_alt_rounded,
                      onPressed: () => context.push(AppRoutes.register),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
