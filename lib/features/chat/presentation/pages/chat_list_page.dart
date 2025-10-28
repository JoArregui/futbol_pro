import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_room.dart';
import '../bloc/chat_bloc.dart';
import 'chat_room_page.dart';
// Importa la página de detalle si ya la tienes (ejemplo)
// import 'chat_room_page.dart'; 

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Disparar la suscripción al Stream al inicio
    // Esto asegura que el BLoC empiece a escuchar los cambios en la lista de salas.
    context.read<ChatBloc>().add(ChatRoomsSubscriptionRequested());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas de Chat (FutbolPro)'),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            // Muestra un Snackbar o Toast al usuario en caso de error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          // 2. Manejo de Estados
          if (state is ChatInitial || state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatError) {
            return Center(child: Text(state.message));
          }

          // Este es el estado donde se muestran las salas
          if (state is ChatRoomsLoaded) {
            return _ChatRoomsView(rooms: state.rooms);
          }
          
          // Fallback
          return const Center(child: Text('Estado desconocido.'));
        },
      ),
    );
  }
}

// Widget auxiliar para mostrar la lista de salas
class _ChatRoomsView extends StatelessWidget {
  final List<ChatRoom> rooms;

  const _ChatRoomsView({required this.rooms});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const Center(child: Text('No hay salas de chat disponibles.'));
    }

    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return ListTile(
          leading: const Icon(Icons.group),
          title: Text(room.title), // Asumimos que ChatRoom tiene un campo 'title'
          subtitle: Text('Miembros: ${room.memberIds.length}'), // Asumimos 'memberIds'
          onTap: () {
            // 3. Disparar el evento para seleccionar la sala y navegar
            context.read<ChatBloc>().add(ChatRoomSelected(room.id));
            
            // Navegación a la página de chat específica
            Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ChatRoomPage(chatRoomId: room.id),
              ),
            );
          },
        );
      },
    );
  }
}