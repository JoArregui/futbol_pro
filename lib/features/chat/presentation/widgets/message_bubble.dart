import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroupChat;
  const MessageBubble({super.key, required this.message, required this.isMe, this.isGroupChat = false});

  Color _senderColor(String name) {
    final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.indigo, Colors.green];
    return colors[name.hashCode % colors.length];
  }

  Widget _tick(MessageStatus s) {
    IconData icon;
    Color color = Colors.white70;
    switch (s) {
      case MessageStatus.sending:
        return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70));
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = const Color(0xFF53BDEB);
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red.shade300;
        break;
    }
    return Icon(icon, size: 14, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.timestamp);
    final shouldShowSenderName = !isMe && isGroupChat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (shouldShowSenderName)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(message.senderName, style: TextStyle(color: _senderColor(message.senderName), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF005C4B) : Colors.white,
                borderRadius: BorderRadius.circular(8).copyWith(
                  topRight: Radius.circular(isMe ? 0 : 8),
                  topLeft: Radius.circular(isMe ? 8 : 0),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 1, offset: const Offset(0, 1))],
              ),
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 4),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: isMe ? 56 : 38, bottom: 2),
                    child: Text(message.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15, height: 1.3)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade600, fontSize: 11)),
                        if (isMe) ...[const SizedBox(width: 4), _tick(message.status)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}