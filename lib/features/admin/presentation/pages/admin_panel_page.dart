import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/consts.dart';
import '../../../../core/injection_container.dart';
import '../../../../core/services/file_download_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../bloc/admin_bloc.dart';

/// Panel superadmin completo — estilo deportivo premium oscuro.
/// Gestiona: equipos, jugadores, campos, árbitros, ligas,
/// amistosos, torneos y finanzas.
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_rounded), text: 'Panel'),
    Tab(icon: Icon(Icons.shield_rounded), text: 'Equipos'),
    Tab(icon: Icon(Icons.group_rounded), text: 'Jugadores'),
    Tab(icon: Icon(Icons.stadium_rounded), text: 'Campos'),
    Tab(icon: Icon(Icons.sports_rounded), text: 'Árbitros'),
    Tab(icon: Icon(Icons.emoji_events_rounded), text: 'Ligas'),
    Tab(icon: Icon(Icons.sports_soccer_rounded), text: 'Amistosos'),
    Tab(icon: Icon(Icons.military_tech_rounded), text: 'Torneos'),
    Tab(icon: Icon(Icons.payments_rounded), text: 'Finanzas'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
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
    return Scaffold(
      body: HeroBackground(
        child: Column(
          children: [
            _Header(
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: AppColors.lime,
              unselectedLabelColor: AppColors.textDim,
              indicatorColor: AppColors.lime,
              indicatorWeight: 3,
              tabAlignment: TabAlignment.start,
              tabs: _tabs,
            ),
            Expanded(
              child: BlocConsumer<AdminBloc, AdminState>(
                listener: (context, state) {
                  if (state is AdminError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is AdminLoading || state is AdminActionRunning) {
                    final msg = state is AdminActionRunning
                        ? state.message
                        : 'Cargando panel...';
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientLime,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            msg,
                            style: const TextStyle(color: AppColors.textDim),
                          ),
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
                          AppButton(
                            label: 'Reintentar',
                            icon: Icons.refresh_rounded,
                            expanded: false,
                            onPressed: () => context.read<AdminBloc>().add(
                              const AdminLoadRequested(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is! AdminLoaded) {
                    return const Center(child: Text('Iniciando panel...'));
                  }
                  return TabBarView(
                    controller: _tab,
                    children: [
                      _DashboardTab(state: state),
                      _TeamsTab(state: state),
                      _PlayersTab(state: state, searchCtrl: _searchCtrl),
                      _FieldsTab(state: state),
                      _RefereesTab(state: state),
                      _LeaguesTab(state: state),
                      _FriendliesTab(state: state),
                      _TournamentsTab(state: state),
                      _FinanceTab(state: state),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          _IconBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PANEL SUPERADMIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Gestión total del club',
                  style: TextStyle(color: AppColors.textDim, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppColors.gradientLime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, size: 15, color: Colors.black),
                SizedBox(width: 5),
                Text(
                  'SUPERADMIN',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

// ---------------- Panel / Dashboard ----------------

class _DashboardTab extends StatelessWidget {
  final AdminLoaded state;
  const _DashboardTab({required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    final cards = [
      _MiniStat('Usuarios', '${s.users}', Icons.group_rounded),
      _MiniStat('Equipos', '${state.teams.length}', Icons.shield_rounded),
      _MiniStat('Jugadores', '${state.players.length}', Icons.person_rounded),
      _MiniStat('Campos', '${s.fields}', Icons.stadium_rounded),
      _MiniStat(
        'Amistosos',
        '${state.friendlies.length}',
        Icons.sports_soccer_rounded,
      ),
      _MiniStat('Ligas', '${state.leagues.length}', Icons.emoji_events_rounded),
      _MiniStat(
        'Torneos',
        '${state.tournaments.length}',
        Icons.military_tech_rounded,
      ),
      _MiniStat('Árbitros', '${state.referees.length}', Icons.sports_rounded),
      _MiniStat(
        'Ingresos',
        '${state.finance.totalRevenue.toStringAsFixed(0)} €',
        Icons.payments_rounded,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppCard(
          gradientColors: const [Color(0xFF2A3F10), Color(0xFF141E0C)],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado del club',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '${s.users} usuarios · ${s.matches} partidos',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mes: ${state.finance.monthRevenue.toStringAsFixed(0)} € · Pendiente: ${state.finance.pending.toStringAsFixed(0)} €',
                      style: const TextStyle(
                        color: AppColors.lime,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientLime,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(
          title: 'Resumen operativo',
          subtitle: 'Todo el club de un vistazo',
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, i) => cards[i],
        ),
        const SizedBox(height: 14),
        const SectionHeader(
          title: 'Actividad reciente',
          subtitle: 'Quién hizo qué (auditoría superadmin)',
        ),
        const SizedBox(height: 8),
        if (state.audit.isEmpty)
          const AppCard(
            child: Text(
              'Sin actividad registrada todavía.',
              style: TextStyle(color: AppColors.textDim),
            ),
          )
        else
          ...state.audit
              .take(8)
              .map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: AppColors.lime,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a.action} · ${a.entity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${a.actorEmail} · ${a.createdAt}',
                                style: const TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.lime, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textDim),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------- Equipos ----------------

class _TeamsTab extends StatelessWidget {
  final AdminLoaded state;
  const _TeamsTab({required this.state});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppButton(
          label: 'Nuevo equipo',
          icon: Icons.add_rounded,
          onPressed: () => _teamDialog(context, null),
        ),
        const SizedBox(height: 12),
        ...state.teams.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientLime,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            t.name.isEmpty ? '?' : t.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${t.league} · ${t.players} jugadores · Cap: ${t.captain}',
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Gestionar plantilla',
                        icon: const Icon(
                          Icons.group_add_rounded,
                          color: AppColors.lime,
                        ),
                        onPressed: () => _squadSheet(context, t.id, t.name),
                      ),
                      IconButton(
                        tooltip: 'Renombrar',
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AppColors.textDim,
                        ),
                        onPressed: () => _teamDialog(context, t),
                      ),
                      IconButton(
                        tooltip: 'Borrar equipo',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                        onPressed: () => _confirmDelete(context, t.id, t.name),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.teams.isEmpty)
          const Text(
            'Sin equipos. Crea el primero.',
            style: TextStyle(color: AppColors.textDim),
          ),
      ],
    );
  }

  void _teamDialog(BuildContext context, dynamic team) {
    final name = TextEditingController(text: team?.name ?? '');
    final league = TextEditingController();
    final isEdit = team != null;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Renombrar equipo' : 'Nuevo equipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre del equipo'),
            ),
            if (!isEdit) ...[
              const SizedBox(height: 10),
              TextField(
                controller: league,
                decoration: const InputDecoration(labelText: 'Liga (opcional)'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              final bloc = context.read<AdminBloc>();
              if (isEdit) {
                bloc.add(AdminUpdateTeamRequested(team.id, name.text.trim()));
              } else {
                bloc.add(
                  AdminCreateTeamRequested(
                    name.text.trim(),
                    league.text.trim(),
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar equipo'),
        content: Text(
          '¿Borrar "$name"? Sus jugadores quedan libres, no se borran sus cuentas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<AdminBloc>().add(AdminDeleteTeamRequested(id));
              Navigator.pop(context);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  void _squadSheet(BuildContext context, String teamId, String teamName) {
    final bloc = context.read<AdminBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => _SquadManager(
          teamId: teamId,
          teamName: teamName,
          bloc: bloc,
          allPlayers: (bloc.state is AdminLoaded)
              ? (bloc.state as AdminLoaded).players
              : const [],
        ),
      ),
    );
  }
}

/// Gestiona la plantilla: añade jugadores existentes y quita miembros.
class _SquadManager extends StatefulWidget {
  final String teamId;
  final String teamName;
  final AdminBloc bloc;
  final List<dynamic> allPlayers;
  const _SquadManager({
    required this.teamId,
    required this.teamName,
    required this.bloc,
    required this.allPlayers,
  });

  @override
  State<_SquadManager> createState() => _SquadManagerState();
}

class _SquadManagerState extends State<_SquadManager> {
  List<dynamic> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.bloc.repository.getTeamPlayers(widget.teamId);
    if (!mounted) return;
    setState(() {
      _members = res.getOrElse(() => []);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final memberIds = _members.map((e) => (e as dynamic).id as String).toSet();
    final available = widget.allPlayers
        .where((p) => !memberIds.contains((p as dynamic).id as String))
        .toList();
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ListView(
        children: [
          Text(
            'Plantilla · ${widget.teamName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${_members.length} jugadores en el equipo',
            style: const TextStyle(color: AppColors.textDim),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_members.isEmpty)
            const Text(
              'Sin jugadores. Añade desde abajo.',
              style: TextStyle(color: AppColors.textDim),
            )
          else
            ..._members.map((m) {
              final p = m as dynamic;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (p.nickname.isEmpty ? '?' : p.nickname[0].toUpperCase())
                        .toString(),
                  ),
                ),
                title: Text(p.nickname?.toString() ?? ''),
                subtitle: Text(p.name?.toString() ?? ''),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: () async {
                    await widget.bloc.repository.removePlayerFromTeam(
                      teamId: widget.teamId,
                      playerId: p.id.toString(),
                    );
                    _load();
                    widget.bloc.add(const AdminLoadRequested());
                  },
                ),
              );
            }),
          const Divider(height: 28),
          const Text(
            'Añadir jugador',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          // Botón para crear jugador manual (sin cuenta en la app)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_add_rounded, color: AppColors.lime),
              label: const Text('Crear jugador manual', style: TextStyle(color: AppColors.lime)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.lime),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showCreateManualPlayerDialog(context),
            ),
          ),
          ...available.take(20).map((p) {
            final pl = p as dynamic;
            return ListTile(
              leading: const Icon(
                Icons.person_add_alt_rounded,
                color: AppColors.lime,
              ),
              title: Text(pl.nickname?.toString() ?? ''),
              subtitle: Text(pl.name?.toString() ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.lime),
                onPressed: () async {
                  await widget.bloc.repository.addPlayerToTeam(
                    teamId: widget.teamId,
                    playerId: pl.id.toString(),
                  );
                  _load();
                  widget.bloc.add(const AdminLoadRequested());
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showCreateManualPlayerDialog(BuildContext context) async {
    final nickCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear jugador manual'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nickCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apodo (nickname) *',
                  hintText: 'Ej: ElMatador9',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Mínimo 2 caracteres.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  hintText: 'jugador@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!v.contains('@')) return 'Email inválido.';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              
              final messenger = ScaffoldMessenger.of(context);
              final result = await widget.bloc.repository.createManualPlayer(
                apodo: nickCtrl.text.trim(),
                nombre: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
              );
              
              result.fold(
                (failure) => messenger.showSnackBar(
                  SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: AppColors.danger),
                ),
                (player) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Jugador "${player.nickname}" creado ✓')),
                  );
                  _load();
                  widget.bloc.add(const AdminLoadRequested());
                },
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

// ---------------- Jugadores ----------------

class _PlayersTab extends StatelessWidget {
  final AdminLoaded state;
  final TextEditingController searchCtrl;
  const _PlayersTab({required this.state, required this.searchCtrl});
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar jugador / email',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: (v) =>
                      bloc.add(AdminUsersSearchRequested(v.trim())),
                ),
              ),
              const SizedBox(width: 8),
              if (state.searchingUsers)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (state.selectedUserIds.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  '${state.selectedUserIds.length} sel.',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                DropdownButton<String>(
                  hint: const Text('Rol'),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'player', child: Text('player')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                    DropdownMenuItem(
                      value: 'superadmin',
                      child: Text('superadmin'),
                    ),
                  ],
                  onChanged: (r) {
                    if (r != null) {
                      bloc.add(AdminBulkRoleRequested(r));
                    }
                  },
                ),
                IconButton(
                  onPressed: () => bloc.add(const AdminBulkDeleteRequested()),
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            children: [
              const SectionHeader(
                title: 'Jugadores',
                subtitle: 'Plantilla y roles',
              ),
              const SizedBox(height: 8),
              ...state.players.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.lime.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            p.nickname.isEmpty
                                ? '?'
                                : p.nickname[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.nickname} · ${p.team}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${p.name} · ⚽ ${p.goals} · ⭐ ${p.rating}',
                                style: const TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SectionHeader(
                title: 'Cuentas',
                subtitle: 'Roles y accesos',
              ),
              ...state.users.map((u) {
                final sel = state.selectedUserIds.contains(u.id);
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: CheckboxListTile(
                    value: sel,
                    activeColor: AppColors.lime,
                    checkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onChanged: (v) => bloc.add(
                      AdminUsersSelectionChanged(
                        userId: u.id,
                        selected: v ?? false,
                      ),
                    ),
                    title: Text(
                      u.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${u.nickname} — rol: ${u.role}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- Campos ----------------

class _FieldsTab extends StatelessWidget {
  final AdminLoaded state;
  const _FieldsTab({required this.state});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppButton(
          label: 'Añadir campo',
          icon: Icons.add_rounded,
          onPressed: () => _fieldDialog(context),
        ),
        const SizedBox(height: 12),
        const SectionHeader(
          title: 'Campos',
          subtitle:
              'Activa/mantenimiento con el switch. Borra con la papelera (si no tiene reservas).',
        ),
        const SizedBox(height: 10),
        ...state.fields.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.stadium_rounded,
                      color: AppColors.lime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '\$${f.price}/h · Cap ${f.capacity} · ${f.status}',
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: f.status == 'disponible',
                    activeThumbColor: AppColors.lime,
                    onChanged: (v) => context.read<AdminBloc>().add(
                      AdminToggleFieldRequested(
                        f.id,
                        v ? 'disponible' : 'mantenimiento',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar campo',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Quitar campo'),
                        content: Text(
                          '¿Quitar "${f.name}"? Solo si no tiene reservas.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.danger,
                            ),
                            onPressed: () {
                              context.read<AdminBloc>().add(
                                AdminDeleteFieldRequested(f.id),
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Quitar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _fieldDialog(BuildContext context) {
    final name = TextEditingController();
    final price = TextEditingController(text: '50');
    final cap = TextEditingController(text: '14');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir campo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '€/hora'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: cap,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacidad'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              context.read<AdminBloc>().add(
                AdminCreateFieldRequested(
                  name.text.trim(),
                  double.tryParse(price.text) ?? 50,
                  int.tryParse(cap.text) ?? 14,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }
}

// ---------------- Árbitros ----------------

class _RefereesTab extends StatelessWidget {
  final AdminLoaded state;
  const _RefereesTab({required this.state});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppButton(
          label: 'Añadir árbitro',
          icon: Icons.add_rounded,
          onPressed: () {
            final name = TextEditingController();
            final fee = TextEditingController(text: '20');
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Añadir árbitro'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fee,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarifa €'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (name.text.trim().isEmpty) return;
                      context.read<AdminBloc>().add(
                        AdminCreateRefereeRequested(
                          name.text.trim(),
                          double.tryParse(fee.text) ?? 20,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Añadir'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const SectionHeader(
          title: 'Árbitros',
          subtitle:
              'Toca el badge para activar/suspender. Papelera para quitar.',
        ),
        const SizedBox(height: 10),
        ...state.referees.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.sports_rounded,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '⭐ ${r.rating} · \$${r.fee} · ${r.status}',
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.read<AdminBloc>().add(
                      AdminToggleRefereeRequested(
                        r.id,
                        r.status == 'activo' ? 'suspendido' : 'activo',
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: r.status == 'activo'
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        r.status,
                        style: TextStyle(
                          color: r.status == 'activo'
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar árbitro',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                    onPressed: () => context.read<AdminBloc>().add(
                      AdminDeleteRefereeRequested(r.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Ligas ----------------

class _LeaguesTab extends StatelessWidget {
  final AdminLoaded state;
  const _LeaguesTab({required this.state});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppButton(
          label: 'Nueva liga',
          icon: Icons.add_rounded,
          onPressed: () {
            final c = TextEditingController();
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Nueva liga'),
                content: TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la liga',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (c.text.trim().isEmpty) return;
                      context.read<AdminBloc>().add(
                        AdminCreateLeagueRequested(c.text.trim()),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Crear'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ...state.leagues.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientLime,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${l.teams} equipos · ${l.status}',
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Amistosos ----------------

class _FriendliesTab extends StatelessWidget {
  final AdminLoaded state;
  const _FriendliesTab({required this.state});
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    final list = state.friendlies.isEmpty ? state.matches : state.friendlies;
    return Column(
      children: [
        if (state.selectedMatchIds.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  '${state.selectedMatchIds.length} sel.',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                AppButton.danger(
                  label: 'Cancelar',
                  icon: Icons.cancel_rounded,
                  expanded: false,
                  onPressed: () =>
                      bloc.add(const AdminBulkCancelMatchesRequested()),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final m = list[i];
              final sel = state.selectedMatchIds.contains(m.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: CheckboxListTile(
                    value: sel,
                    activeColor: AppColors.lime,
                    checkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onChanged: (v) => bloc.add(
                      AdminMatchesSelectionChanged(
                        matchId: m.id,
                        selected: v ?? false,
                      ),
                    ),
                    title: Text(
                      'Amistoso ${m.id} — ${m.status}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('Campo ${m.fieldId} · ${m.time}'),
                    secondary: const Icon(
                      Icons.sports_soccer_rounded,
                      color: AppColors.lime,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------- Torneos ----------------

class _TournamentsTab extends StatelessWidget {
  final AdminLoaded state;
  const _TournamentsTab({required this.state});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const SectionHeader(
          title: 'Torneos',
          subtitle: 'Fases y equipos inscritos',
        ),
        const SizedBox(height: 10),
        ...state.tournaments.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              gradientColors: const [Color(0xFF241A08), Color(0xFF14110A)],
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${t.phase} · ${t.teams} equipos',
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Finanzas ----------------

class _FinanceTab extends StatelessWidget {
  final AdminLoaded state;
  const _FinanceTab({required this.state});
  Future<void> _exportCsv(BuildContext context) async {
    try {
      final path = await sl<FileDownloadService>().downloadText(
        apiPath: '${AppConsts.effectiveBaseUrl}/admin/finance.csv',
        filename:
            'finanzas-${DateTime.now().toIso8601String().substring(0, 10)}.csv',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('CSV guardado: $path')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error export: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = state.finance;
    final max = f.byMonth.isEmpty
        ? 1.0
        : f.byMonth.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppButton(
          label: 'Exportar CSV',
          icon: Icons.download_rounded,
          onPressed: () => _exportCsv(context),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MoneyCard('Total', f.totalRevenue, AppColors.lime),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyCard('Este mes', f.monthRevenue, AppColors.field),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MoneyCard('Pendiente', f.pending, AppColors.warning),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Ingresos por mes',
                subtitle: 'Reservas + torneos + arbitraje',
              ),
              const SizedBox(height: 14),
              ...f.byMonth.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '\$${p.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: max == 0 ? 0 : (p.value / max).clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.lime,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoneyCard extends StatelessWidget {
  final String label;
  final double value;
  final Color accent;
  const _MoneyCard(this.label, this.value, this.accent);
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_rounded, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(0)} €',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
