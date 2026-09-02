import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/chat_room.dart';

class ChatTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  const ChatTile({super.key, required this.room, required this.onTap});

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return DateFormat('HH:mm').format(dt);
    if (diff == 1) return 'ayer';
    if (diff < 7) return DateFormat('EEE', 'es_ES').format(dt);
    return DateFormat('dd/MM/yy').format(dt);
  }

  String _preview() {
    if (room.lastMessage == null) return 'Toca para iniciar el chat';
    final t = room.lastMessage!.text;
    return t.length > 32 ? '${t.substring(0, 32)}…' : t;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = room.unreadCount > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: room.isGroup ? const Color(0xFF25D366) : const Color(0xFF54656F),
                  backgroundImage: room.avatarUrl != null ? NetworkImage(room.avatarUrl!) : null,
                  child: room.avatarUrl == null ? Icon(room.isGroup ? Icons.groups : Icons.person, color: Colors.white) : null,
                ),
                if (room.isPinned)
                  Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.push_pin, size: 10, color: Color(0xFF54656F)))),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600, fontSize: 16, color: const Color(0xFF111B21)))),
                      const SizedBox(width: 6),
                      Text(_timeLabel(room.lastActive ?? room.lastMessage?.timestamp), style: TextStyle(fontSize: 12, color: hasUnread ? const Color(0xFF25D366) : const Color(0xFF667781), fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (room.lastMessage != null && room.lastMessage!.senderId.isNotEmpty) ...[
                        const Icon(Icons.done_all, size: 14, color: Color(0xFF53BDEB)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(child: Text(_preview(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: hasUnread ? const Color(0xFF111B21) : const Color(0xFF667781), fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal, fontSize: 13.5))),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Center(child: Text('${room.unreadCount > 99 ? '99+' : room.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                        )
                      else if (room.isMuted)
                        const Icon(Icons.volume_off, size: 16, color: Color(0xFF667781)),
                    ],
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
