import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Aún no hay mensajes. ¡Sé el primero!', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      // Invertir el orden para que los mensajes más recientes estén abajo
      reverse: true,
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      // Muestra la lista invertida, pero usamos el índice normal para el acceso
      itemCount: messages.length,
      itemBuilder: (context, index) {
        // Accede a los mensajes desde el final de la lista para mostrarlos abajo
        final message = messages[messages.length - 1 - index];
        final isMe = message.senderId == currentUserId;

        return MessageBubble(message: message, isMe: isMe);
      },
    );
  }
}