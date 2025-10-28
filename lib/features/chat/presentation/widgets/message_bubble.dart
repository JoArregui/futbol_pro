import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroupChat = !isMe && message.senderName != 'Usuario Actual'; // Simple heurística de grupo
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Nombre del remitente (solo si no soy yo y no estamos asumiendo un nombre genérico)
            if (!isMe && isGroupChat)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                child: Text(
                  message.senderName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Burbuja del mensaje
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe ? theme.primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(16).copyWith(
                  // Bordes redondeados para un look de chat moderno
                  topRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  topLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}