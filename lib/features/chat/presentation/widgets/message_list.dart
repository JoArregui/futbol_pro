import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final bool isGroupChat;
  final bool isTyping;

  const MessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    this.isGroupChat = false,
    this.isTyping = false,
  });

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(mDay).inDays;
    if (diff == 0) return 'HOY';
    if (diff == 1) return 'AYER';
    return DateFormat('dd MMM yyyy', 'es_ES').format(d).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !isTyping) {
      return const Center(
        child: Text(
          'Aún no hay mensajes. ¡Sé el primero!',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Agrupar por fecha de arriba a abajo
    final items = <Widget>[];
    DateTime? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final m = messages[i];
      final d = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);

      if (lastDate == null || d != lastDate) {
        items.add(_DateChip(label: _dateLabel(m.timestamp)));
        lastDate = d;
      }

      final isMe = m.senderId == currentUserId;
      items.add(
        MessageBubble(message: m, isMe: isMe, isGroupChat: isGroupChat),
      );
    }

    if (isTyping) {
      items.add(const _TypingIndicator());
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F2FA),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF54656F),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 4, left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ).copyWith(topLeft: const Radius.circular(4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'escribiendo',
            style: TextStyle(
              color: Color(0xFF54656F),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
    child: Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF54656F),
        shape: BoxShape.circle,
      ),
    ),
  );
}
