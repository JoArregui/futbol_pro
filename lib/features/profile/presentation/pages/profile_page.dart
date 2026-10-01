import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_loaded_view.dart';
import '../widgets/profile_error_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Carga única (antes se disparaba en cada build). Usa los datos reales
    // de la sesión para el fallback de creación: el backend ya crea el
    // perfil en /auth/register, así que esto casi siempre hace fetch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<ProfileBloc>();
      final fallbackName =
          bloc.currentUserName.isNotEmpty ? bloc.currentUserName : 'Jugador';
      bloc.add(ProfileLoadRequested(
        bloc.currentUserId,
        email: '',
        nickname: fallbackName,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
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
