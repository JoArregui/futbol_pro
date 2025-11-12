import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_loaded_view.dart';
import '../widgets/profile_error_view.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileBloc>();
    bloc.add(ProfileLoadRequested(bloc.currentUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        automaticallyImplyLeading: true,
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
