import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/chat_room.dart';
import '../bloc/chat_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart'; // ⚠️ Importar AuthBloc

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // 1. Método para cargar chats
  void _loadChatsIfAuthenticated(BuildContext context, AuthState authState) {
    if (authState is AuthAuthenticated) {
      // ✅ Dispara el evento de carga de salas de chat
      // Usamos el nombre de evento correcto que definiremos en la sección 3
      context.read<ChatBloc>().add(ChatRoomsSubscriptionRequested());
    }
  }

  @override
  void initState() {
    super.initState();
    // 2. Disparar la carga si ya está autenticado al iniciar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      _loadChatsIfAuthenticated(context, authState);
    });
  }

  void _navigateToRoom(BuildContext context, ChatRoom room) {
    context.read<ChatBloc>().add(ChatRoomSelected(room.id));
    context.push('/chat/${room.id}');
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
        title: const Text('Chats'),
        backgroundColor: Colors.blueAccent,
      ),
      // 🚀 Usamos BlocListener para reaccionar al cambio en el AuthBloc (ej: después del login)
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          // 3. Si el estado del AuthBloc cambia a Autenticado, disparamos la carga de chats
          if (authState is AuthAuthenticated) {
            _loadChatsIfAuthenticated(context, authState);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>( // Evaluamos el estado del AuthBloc
          builder: (context, authState) {
            
            // 4. Si NO está autenticado, mostramos el mensaje de error de autenticación
            if (authState is! AuthAuthenticated) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Inicia sesión para ver tus chats.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Ir a Iniciar Sesión'),
                    ),
                  ],
                ),
              );
            }
            
            // 5. Si SÍ está autenticado, pasamos a evaluar el estado del ChatBloc
            return BlocBuilder<ChatBloc, ChatState>(
              builder: (context, chatState) {
                if (chatState is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (chatState is ChatError) {
                  return Center(
                      child: Text('Error al cargar chats: ${chatState.message}'));
                }
                if (chatState is ChatRoomsLoaded) {
                  if (chatState.rooms.isEmpty) {
                    return const Center(
                        child: Text('No tienes salas de chat disponibles.'));
                  }
                  return ListView.builder(
                    itemCount: chatState.rooms.length,
                    itemBuilder: (context, index) {
                      final room = chatState.rooms[index];
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
                
                // Si está autenticado pero el ChatBloc está en estado inicial/desconocido, 
                // le pedimos que recargue.
                return const Center(
                    child: Text('Presiona el botón de recarga para cargar los chats.'));
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Disparar recarga manualmente
          final authState = context.read<AuthBloc>().state;
          _loadChatsIfAuthenticated(context, authState);
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}