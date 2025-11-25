import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final bool isGroupChat; // 🟢 Añadido para la lógica de visualización

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    this.isGroupChat = false, // 🟢 Default a false (chat privado)
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Aún no hay mensajes. ¡Sé el primero!',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      reverse: true,
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index]; // 🟢 Los mensajes ya vienen invertidos desde el BLoC
        final isMe = message.senderId == currentUserId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          isGroupChat: isGroupChat, // 🟢 Pasando la propiedad
        );
      },
    );
  }
}