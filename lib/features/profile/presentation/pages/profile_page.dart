import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_loaded_view.dart';
import '../widgets/profile_error_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Disparar la carga del perfil al inicio
    // Usamos el ID del usuario actual inyectado en el BLoC
    final bloc = context.read<ProfileBloc>();
    bloc.add(ProfileLoadRequested(bloc.currentUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.blueAccent,
      ),
      // 2. Usar BlocListener para notificaciones (ej. éxito de actualización)
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Perfil actualizado exitosamente!')),
            );
          }
          if (state is ProfileError && state.message.contains('actualizar')) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error al guardar: ${state.message}')),
            );
          }
        },
        // 3. Usar BlocBuilder para construir la UI según el estado
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              // Vista auxiliar para errores (solo para mantener la página limpia)
              return ProfileErrorView(message: state.message);
            }

            if (state is ProfileLoaded) {
              // Vista principal con los datos del perfil y el formulario de edición
              return ProfileLoadedView(
                profile: state.profile,
                isUpdating: state.isUpdating,
              );
            }

            return const Center(child: Text('Estado desconocido del perfil.'));
          },
        ),
      ),
    );
  }
}