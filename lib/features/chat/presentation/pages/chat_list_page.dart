import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/chat_room.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_tile.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) context.read<ChatBloc>().add(ChatRoomsSubscriptionRequested());
    });
  }

  void _navigateToRoom(ChatRoom room) {
    context.read<ChatBloc>().add(ChatRoomSelected(room.id));
    context.push('/chat/${room.id}');
  }

  List<ChatRoom> _filter(List<ChatRoom> rooms) {
    var list = rooms;
    // tab filter
    if (_tab.index == 1) list = list.where((r) => r.unreadCount > 0).toList();
    if (_tab.index == 2) list = list.where((r) => r.isGroup).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((r) => r.title.toLowerCase().contains(q) || (r.lastMessage?.text.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Buscar', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('Futbol Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(_searching ? Icons.close : Icons.search), onPressed: () => setState(() { _searching = !_searching; if (!_searching) { _query = ''; _searchCtrl.clear(); } })),
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
          PopupMenuButton(itemBuilder: (_) => const [PopupMenuItem(value: 'newGroup', child: Text('Nuevo grupo')), PopupMenuItem(value: 'newChat', child: Text('Nuevo chat'))], onSelected: (v) { if (v == 'newChat') context.push('/chat/new'); }),
        ],
        bottom: TabBar(
          controller: _tab,
          onTap: (_) => setState(() {}),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Todos'), Tab(text: 'No leídos'), Tab(text: 'Grupos')],
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (c, s) { if (s is AuthAuthenticated) c.read<ChatBloc>().add(ChatRoomsSubscriptionRequested()); },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (c, authState) {
            if (authState is! AuthAuthenticated) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Inicia sesión para ver tus chats.'), const SizedBox(height: 12), ElevatedButton.icon(onPressed: () => context.go('/login'), icon: const Icon(Icons.login), label: const Text('Ir a Iniciar Sesión'))]));
            }
            return BlocBuilder<ChatBloc, ChatState>(
              builder: (c, s) {
                if (s is ChatLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF075E54)));
                if (s is ChatError) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Error: ${s.message}'), const SizedBox(height: 8), ElevatedButton(onPressed: () => context.read<ChatBloc>().add(ChatRoomsSubscriptionRequested()), child: const Text('Reintentar'))]));
                if (s is ChatRoomsLoaded) {
                  final filtered = _filter(s.rooms);
                  if (filtered.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFF667781)), const SizedBox(height: 12), Text(_query.isNotEmpty ? 'Sin resultados para "$_query"' : s.rooms.isEmpty ? 'No tienes chats. ¡Crea uno!' : 'Sin chats en esta pestaña', style: const TextStyle(color: Color(0xFF667781))), const SizedBox(height: 12), if (s.rooms.isEmpty) ElevatedButton.icon(onPressed: () => context.push('/chat/new'), icon: const Icon(Icons.chat), label: const Text('Nuevo chat'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white))]));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ChatBloc>().add(ChatRoomsSubscriptionRequested()),
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: Color(0xFFF0F0F0)),
                      itemBuilder: (_, i) => ChatTile(room: filtered[i], onTap: () => _navigateToRoom(filtered[i])),
                    ),
                  );
                }
                return Center(child: ElevatedButton(onPressed: () => context.read<ChatBloc>().add(ChatRoomsSubscriptionRequested()), child: const Text('Cargar chats')));
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        onPressed: () => context.push('/chat/new'),
        child: const Icon(Icons.chat),
      ),
    );
  }

  @override
  void dispose() { _tab.dispose(); _searchCtrl.dispose(); super.dispose(); }
}