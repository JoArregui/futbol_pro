import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_loaded_view.dart';
import '../widgets/profile_error_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileBloc>();
    
    // 🚀 Importante: El email y el nickname deben venir del BLoC de Autenticación.
    // Usamos valores placeholder aquí para simular el evento de carga/creación.
    const String userEmailPlaceholder = 'usuario.autenticado@ejemplo.com'; 
    const String userNicknamePlaceholder = 'NuevoUser'; 
    
    // Disparar la carga del perfil con la información necesaria para la creación
    // (Solo se crea si el fetch falla con "Usuario no encontrado").
    bloc.add(ProfileLoadRequested(
      bloc.currentUserId, 
      email: userEmailPlaceholder, 
      nickname: userNicknamePlaceholder
    ));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        automaticallyImplyLeading: false,
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('✅ Perfil actualizado exitosamente!')),
            );
          }
          if (state is ProfileError && state.message.contains('actualizar')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error al guardar: ${state.message}')),
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              return ProfileErrorView(message: state.message);
            }

            if (state is ProfileLoaded) {
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