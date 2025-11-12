import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';

class ChatInput extends StatefulWidget {
  final String roomId;
  final String senderId;
  final bool isSending;

  const ChatInput({
    super.key,
    required this.roomId,
    required this.senderId,
    required this.isSending,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  bool _isButtonEnabled = false;

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      context.read<ChatBloc>().add(
            ChatMessageSent(
              roomId: widget.roomId,
              senderId: widget.senderId,
              content: text,
            ),
          );
      _textController.clear();
      setState(() => _isButtonEnabled = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Escribe un mensaje...',
                ),
                onChanged: (text) {
                  setState(() {
                    _isButtonEnabled = text.trim().isNotEmpty;
                  });
                },
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: widget.isSending
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : const Icon(Icons.send),
              onPressed:
                  _isButtonEnabled && !widget.isSending ? _sendMessage : null,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
