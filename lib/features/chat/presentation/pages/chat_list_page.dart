import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/chat_room.dart';
import '../bloc/chat_bloc.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  void _navigateToRoom(BuildContext context, ChatRoom room) {
    // 1. Disparar el evento para seleccionar la sala y suscribirse a mensajes
    context.read<ChatBloc>().add(ChatRoomSelected(room.id));

    // 2. Navegar a la sala de chat.

    context.push('/chat/${room.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.blueAccent,
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatError) {
            return Center(
                child: Text('Error al cargar chats: ${state.message}'));
          }
          if (state is ChatRoomsLoaded) {
            if (state.rooms.isEmpty) {
              return const Center(
                  child: Text('No tienes salas de chat disponibles.'));
            }
            return ListView.builder(
              itemCount: state.rooms.length,
              itemBuilder: (context, index) {
                final room = state.rooms[index];
                return ListTile(
                  leading: const Icon(Icons.forum, color: Colors.blueAccent),
                  title: Text(room.title),
                  subtitle: Text(
                      room.lastMessage?.text ?? 'Toca para iniciar el chat'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navigateToRoom(context, room),
                );
              },
            );
          }
          return const Center(
              child: Text('Inicia sesión o recarga para ver tus chats.'));
        },
      ),
    );
  }
}
