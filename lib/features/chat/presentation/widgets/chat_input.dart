import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  bool _hasText = false;
  bool _uploading = false;

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty || widget.isSending || _uploading) return;
    context.read<ChatBloc>().add(
      ChatMessageSent(roomId: widget.roomId, content: t),
    );
    _ctrl.clear();
    setState(() => _hasText = false);
    context.read<ChatBloc>().add(
      ChatTypingChanged(roomId: widget.roomId, isTyping: false),
    );
  }

  void _onChanged(String v) {
    final has = v.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    context.read<ChatBloc>().add(
      ChatTypingChanged(roomId: widget.roomId, isTyping: has),
    );
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSend(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndSend(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSend(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() => _uploading = true);
      final caption = _ctrl.text.trim();
      final ref = FirebaseStorage.instance.ref().child(
        'chat_images/${widget.roomId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(
        File(picked.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      context.read<ChatBloc>().add(
        ChatMessageSent(roomId: widget.roomId, content: caption, imageUrl: url),
      );
      _ctrl.clear();
      setState(() {
        _hasText = false;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar la imagen: $e')),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      color: const Color(0xFFF0F0F0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_uploading)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Subiendo imagen…',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: Color(0xFF54656F),
                          ),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            onChanged: _onChanged,
                            onSubmitted: (_) => _send(),
                            minLines: 1,
                            maxLines: 5,
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Mensaje',
                              hintStyle: TextStyle(color: Color(0xFF667781)),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                            color: Color(0xFF54656F),
                          ),
                          onPressed: _uploading ? null : _showAttachSheet,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF54656F),
                          ),
                          onPressed: _uploading
                              ? null
                              : () => _pickAndSend(ImageSource.camera),
                        ),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _hasText ? Icons.send : Icons.mic,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
