import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_colors.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;
  const ChatRoomPage({super.key, required this.chatRoomId});
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _scrollController = ScrollController();
  ChatBloc? _bloc;
  bool _requestedRoom = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc ??= context.read<ChatBloc>();
    if (!_requestedRoom) {
      _requestedRoom = true;
      _bloc!.add(ChatRoomSelected(widget.chatRoomId));
    }
  }

  @override
  void dispose() {
    _bloc?.add(ChatRoomLeft(widget.chatRoomId));
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (ctx, s) {
        if (s is ChatRoomSelectedState) {
          _scrollToBottom();
          if (s.error != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(s.error!), backgroundColor: Colors.red),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is ChatRoomSelectedState &&
            state.room.id == widget.chatRoomId) {
          final isGroup = state.room.isGroup;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: ChatColors.bar(context),
              foregroundColor: Colors.white,
              leadingWidth: 30,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/chat'),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: state.room.avatarUrl != null
                        ? NetworkImage(state.room.avatarUrl!)
                        : null,
                    child: state.room.avatarUrl == null
                        ? Icon(
                            isGroup ? Icons.groups : Icons.person,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.room.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          state.isTyping
                              ? 'escribiendo...'
                              : (isGroup
                                    ? '${state.room.memberIds.length} miembros'
                                    : 'en línea'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
                IconButton(icon: const Icon(Icons.call), onPressed: () {}),
                PopupMenuButton(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'info', child: Text('Ver info')),
                  ],
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                color: ChatColors.roomBackground(context),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: MessageList(
                      messages: state.messages,
                      currentUserId: context.read<ChatBloc>().currentUserId,
                      isGroupChat: isGroup,
                      scrollController: _scrollController,
                      isTyping: state.isTyping,
                    ),
                  ),
                  ChatInput(
                    roomId: widget.chatRoomId,
                    isSending: state.isSending,
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: ChatColors.bar(context),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            title: const Text('Sala de Chat'),
          ),
          body: Center(
            child: (state is ChatLoading)
                ? CircularProgressIndicator(color: ChatColors.bar(context))
                : (state is ChatError)
                ? Text('Error: ${state.message}')
                : const Text('Cargando sala...'),
          ),
        );
      },
    );
  }
}
