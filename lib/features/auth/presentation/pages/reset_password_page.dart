import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:futbol_pro/features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/connection_banner.dart';
import '../../../../routes/app_routes.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? email;
  final String? token;

  const ResetPasswordPage({
    super.key,
    this.email,
    this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  String? _token;
  String? _email;

  @override
  void initState() {
    super.initState();
    // Obtener token y email de los query parameters
    _token = widget.token;
    _email = widget.email;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    _token = _token ?? uri.queryParameters['token'];
    _email = _email ?? uri.queryParameters['email'];
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_token == null || _token!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Token de restablecimiento no encontrado.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      context.read<AuthBloc>().add(
        ResetPasswordRequested(token: _token!, password: _passwordController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.login),
        ),
        title: const Text('Nueva contraseña'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          if (state is ResetPasswordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Contraseña actualizada correctamente. Ya puedes iniciar sesión.'),
              ),
            );
            context.go(AppRoutes.login);
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      'NUEVA CONTRASEÑA 🔐',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_email != null)
                    Center(
                      child: Text(
                        'Restableciendo para: $_email',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      children: [
                        const ConnectionBanner(),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña (mín. 8 caracteres)',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 8)
                              ? 'Mínimo 8 caracteres.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscure,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirma la contraseña.';
                            if (v != _passwordController.text) return 'Las contraseñas no coinciden.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return AppButton(
                              label: 'Guardar nueva contraseña',
                              icon: Icons.check_rounded,
                              loading: state is AuthLoading,
                              onPressed: state is AuthLoading
                                  ? null
                                  : _onSubmit,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        AppButton.ghost(
                          label: 'Cancelar',
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}