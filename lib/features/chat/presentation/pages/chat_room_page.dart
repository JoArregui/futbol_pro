import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Importado para navegación segura
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
          // Determinar si es un chat grupal para pasarlo a MessageList/Bubble
          final isGroupChat = state.room.memberIds.length > 2;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              automaticallyImplyLeading: false,
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
                    isGroupChat: isGroupChat, // 🟢 Pasar la propiedad de chat grupal
                    scrollController: _scrollController,
                  ),
                ),
                // 4. Input y Botón de Envío
                ChatInput(
                  roomId: widget.chatRoomId,
                  isSending: state.isSending,
                ),
              ],
            ),
          );
        }

        // Manejo de estados de carga/error (envueltos en un Scaffold simple)
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            automaticallyImplyLeading: false,
            title: const Text('Sala de Chat'),
            backgroundColor: Colors.blueAccent,
          ),
          body: Center(
            child: (state is ChatLoading)
                ? const CircularProgressIndicator()
                : (state is ChatError)
                    ? Text('Error: ${state.message}')
                    : const Text('Error: Sala no cargada.'),
          ),
        );
      },
    );
  }
}