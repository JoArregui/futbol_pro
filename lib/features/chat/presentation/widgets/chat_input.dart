import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';

class ChatInput extends StatefulWidget {
  final String roomId;
  final bool isSending;
  const ChatInput({super.key, required this.roomId, required this.isSending});
  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty || widget.isSending) return;
    context.read<ChatBloc>().add(ChatMessageSent(roomId: widget.roomId, content: t));
    _ctrl.clear();
    setState(() => _hasText = false);
    context.read<ChatBloc>().add(ChatTypingChanged(roomId: widget.roomId, isTyping: false));
  }

  void _onChanged(String v) {
    final has = v.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    context.read<ChatBloc>().add(ChatTypingChanged(roomId: widget.roomId, isTyping: has));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      color: const Color(0xFFF0F0F0),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF54656F)), onPressed: () {}),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: _onChanged,
                        onSubmitted: (_) => _send(),
                        minLines: 1,
                        maxLines: 5,
                        decoration: const InputDecoration.collapsed(hintText: 'Mensaje', hintStyle: TextStyle(color: Color(0xFF667781))),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF54656F)), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.camera_alt, color: Color(0xFF54656F)), onPressed: () {}),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _hasText ? _send : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                child: Icon(
                  _hasText ? Icons.send : Icons.mic,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}