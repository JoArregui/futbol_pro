import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/admin_bloc.dart';

/// Panel superadmin (web + móvil): estadísticas y modificaciones masivas.
/// Solo accesible con rol superadmin (guard en GoRouter + 403 backend).
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AdminBloc>().add(const AdminLoadRequested()),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Panel Superadmin'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Usuarios'),
            Tab(icon: Icon(Icons.sports_soccer), text: 'Partidos'),
          ],
        ),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading ||
              (state is AdminActionRunning)) {
            final msg = state is AdminActionRunning ? state.message : 'Cargando...';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(msg),
                ],
              ),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<AdminBloc>()
                        .add(const AdminLoadRequested()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          if (state is! AdminLoaded) {
            return const Center(child: Text('Iniciando panel...'));
          }
          return Column(
            children: [
              _StatsRow(state: state, wide: wide),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _UsersTab(state: state, searchCtrl: _searchCtrl),
                    _MatchesTab(state: state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AdminLoaded state;
  final bool wide;
  const _StatsRow({required this.state, required this.wide});

  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    final cards = [
      _StatCard(label: 'Usuarios', value: s.users, icon: Icons.group),
      _StatCard(label: 'Partidos', value: s.matches, icon: Icons.sports_soccer),
      _StatCard(label: 'Canchas', value: s.fields, icon: Icons.stadium),
      _StatCard(label: 'Reservas', value: s.bookings, icon: Icons.bookmark),
      _StatCard(label: 'Chats', value: s.chats, icon: Icons.chat),
    ];
    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: cards
              .map((c) => Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  )))
              .toList(),
        ),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        children:
            cards.map((c) => SizedBox(width: 150, child: c)).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1A237E)),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
}

class _UsersTab extends StatelessWidget {
  final AdminLoaded state;
  final TextEditingController searchCtrl;
  const _UsersTab({required this.state, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar email / apodo',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (v) =>
                      bloc.add(AdminUsersSearchRequested(v.trim())),
                ),
              ),
              const SizedBox(width: 8),
              if (state.searchingUsers)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        if (state.selectedUserIds.isNotEmpty)
          Container(
            color: const Color(0xFFE8EAF6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('${state.selectedUserIds.length} seleccionados',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                DropdownButton<String>(
                  hint: const Text('Rol masivo'),
                  items: const [
                    DropdownMenuItem(value: 'player', child: Text('player')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                    DropdownMenuItem(
                        value: 'superadmin', child: Text('superadmin')),
                  ],
                  onChanged: (r) {
                    if (r != null) bloc.add(AdminBulkRoleRequested(r));
                  },
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => bloc.add(const AdminBulkDeleteRequested()),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Borrar'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: state.users.length,
            itemBuilder: (context, i) {
              final u = state.users[i];
              final sel = state.selectedUserIds.contains(u.id);
              return CheckboxListTile(
                value: sel,
                onChanged: (v) => bloc.add(AdminUsersSelectionChanged(
                    userId: u.id, selected: v ?? false)),
                title: Text(u.email,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${u.nickname} ${u.name} — rol: ${u.role}'),
                secondary: CircleAvatar(child: Text(u.email.isEmpty ? '?' : u.email[0].toUpperCase())),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MatchesTab extends StatelessWidget {
  final AdminLoaded state;
  const _MatchesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    return Column(
      children: [
        if (state.selectedMatchIds.isNotEmpty)
          Container(
            color: const Color(0xFFFFEBEE),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('${state.selectedMatchIds.length} seleccionados',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () =>
                      bloc.add(const AdminBulkCancelMatchesRequested()),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar masivo'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: state.matches.length,
            itemBuilder: (context, i) {
              final m = state.matches[i];
              final sel = state.selectedMatchIds.contains(m.id);
              return CheckboxListTile(
                value: sel,
                onChanged: (v) => bloc.add(AdminMatchesSelectionChanged(
                    matchId: m.id, selected: v ?? false)),
                title: Text('Partido ${m.id} — ${m.status}'),
                subtitle: Text('Campo ${m.fieldId} — ${m.time}'),
                secondary: const Icon(Icons.sports_soccer),
              );
            },
          ),
        ),
      ],
    );
  }
}
