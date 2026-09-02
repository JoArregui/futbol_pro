import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/chat_bloc.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});
  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final _searchCtrl = TextEditingController();
  final _groupUsers = <Map<String, dynamic>>[];
  bool _groupMode = false;

  void _search(String v) {
    context.read<ChatBloc>().add(ChatSearchRequested(v));
  }

  void _createPrivate(Map<String, dynamic> user) {
    final bloc = context.read<ChatBloc>();
    final myId = bloc.currentUserId;
    final otherId = user['id']?.toString() ?? user['uid']?.toString() ?? '';
    if (otherId.isEmpty || myId.isEmpty) return;
    final name = user['nombre']?.toString() ?? user['name']?.toString() ?? user['apodo']?.toString() ?? 'Chat';
    bloc.add(ChatCreateRequested(title: name, type: 'private', memberIds: [myId, otherId]));
    // Esperar un momento y volver a lista: el bloc emitirá y navegará
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.go('/chat');
    });
  }

  void _toggleGroupUser(Map<String, dynamic> user) {
    final id = user['id']?.toString() ?? '';
    final exists = _groupUsers.any((u) => (u['id']?.toString() ?? '') == id);
    setState(() {
      if (exists) {
        _groupUsers.removeWhere((u) => (u['id']?.toString() ?? '') == id);
      } else {
        _groupUsers.add(user);
      }
    });
  }

  void _createGroup() async {
    if (_groupUsers.isEmpty) return;
    final titleCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nombre del grupo'),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Ej: Equipo 5')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(context, titleCtrl.text.trim()), child: const Text('Crear'))],
      ),
    );
    if (name == null || name.isEmpty) return;
    final bloc = context.read<ChatBloc>();
    final ids = [bloc.currentUserId, ..._groupUsers.map((u) => u['id']?.toString() ?? '')];
    bloc.add(ChatCreateRequested(title: name, type: 'general', memberIds: ids));
    if (mounted) context.go('/chat');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search(''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: Text(_groupMode ? 'Nuevo grupo' : 'Nuevo chat'),
        actions: [
          IconButton(
            icon: Icon(_groupMode ? Icons.group : Icons.groups),
            tooltip: _groupMode ? 'Modo chat privado' : 'Modo grupo',
            onPressed: () => setState(() => _groupMode = !_groupMode),
          ),
          if (_groupMode && _groupUsers.isNotEmpty)
            IconButton(icon: const Icon(Icons.check), onPressed: _createGroup),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, apodo o email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          if (_groupMode && _groupUsers.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _groupUsers.map((u) {
                  final name = u['nombre']?.toString() ?? u['apodo']?.toString() ?? '?';
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(children: [
                          CircleAvatar(backgroundImage: u['url_avatar'] != null ? NetworkImage(u['url_avatar']) : null, child: u['url_avatar'] == null ? const Icon(Icons.person) : null),
                          Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => _toggleGroupUser(u), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                        ]),
                        const SizedBox(height: 4),
                        Text(name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (_, state) {
                List<Map<String, dynamic>> users = [];
                bool loading = false;
                if (state is ChatSearchState) {
                  users = state.users;
                  loading = state.isSearching;
                }
                if (loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF075E54)));
                if (users.isEmpty) return const Center(child: Text('Sin resultados', style: TextStyle(color: Color(0xFF667781))));
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final name = u['nombre']?.toString() ?? u['name']?.toString() ?? 'Usuario';
                    final apodo = u['apodo']?.toString() ?? '';
                    final email = u['email']?.toString() ?? '';
                    final selected = _groupMode && _groupUsers.any((x) => (x['id']?.toString() ?? '') == (u['id']?.toString() ?? ''));
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: u['url_avatar'] != null ? NetworkImage(u['url_avatar']) : null, child: u['url_avatar'] == null ? const Icon(Icons.person) : null),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(apodo.isNotEmpty ? '@$apodo • $email' : email, style: const TextStyle(fontSize: 12, color: Color(0xFF667781))),
                      trailing: _groupMode
                          ? Checkbox(value: selected, onChanged: (_) => _toggleGroupUser(u), activeColor: const Color(0xFF25D366))
                          : const Icon(Icons.chat, color: Color(0xFF25D366)),
                      onTap: () => _groupMode ? _toggleGroupUser(u) : _createPrivate(u),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
