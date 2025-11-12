import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;

  const ChatRoomPage({
    super.key,
    required this.chatRoomId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatRoomSelectedState) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state is ChatRoomSelectedState &&
            state.room.id == widget.chatRoomId) {
          return Scaffold(
            appBar: AppBar(
              title: Text(state.room.title),
              backgroundColor: Colors.blueAccent,
            ),
            body: Column(
              children: <Widget>[
                // 3. Área de Mensajes (Usando el nuevo MessageList)
                Expanded(
                  child: MessageList(
                    messages: state.messages,
                    currentUserId: context.read<ChatBloc>().currentUserId,
                    scrollController: _scrollController,
                  ),
                ),
                // 4. Input y Botón de Envío
                ChatInput(
                  roomId: widget.chatRoomId,
                  senderId: context.read<ChatBloc>().currentUserId,
                  isSending: state.isSending,
                ),
              ],
            ),
          );
        }

        // Manejo de estados de carga/error
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ChatError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('Error: Sala no cargada.'));
      },
    );
  }
}
