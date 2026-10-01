import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/league_detail.dart';
import '../bloc/league_bloc.dart';

/// Detalle de liga: fixture por jornadas, tabla, goleadores y equipos.
class LeagueDetailPage extends StatefulWidget {
  final String leagueId;
  final String leagueName;

  const LeagueDetailPage({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  State<LeagueDetailPage> createState() => _LeagueDetailPageState();
}

class _LeagueDetailPageState extends State<LeagueDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<LeagueBloc>().add(
        LeagueDetailRequested(
          leagueId: widget.leagueId,
          leagueName: widget.leagueName,
        ),
      ),
    );
  }

  void _reload() => context.read<LeagueBloc>().add(
    LeagueDetailRequested(
      leagueId: widget.leagueId,
      leagueName: widget.leagueName,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isSuperAdmin =
        authState is AuthAuthenticated && authState.isSuperAdmin;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/tournaments'),
          ),
          automaticallyImplyLeading: false,
          title: Text(widget.leagueName),
          centerTitle: true,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Partidos'),
              Tab(text: 'Tabla'),
              Tab(text: 'Goles'),
              Tab(text: 'Equipos'),
            ],
          ),
        ),
        body: BlocConsumer<LeagueBloc, LeagueState>(
          listener: (context, state) {
            if (state is FixtureGenerated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fixture generado: ${state.partidos} partidos en ${state.jornadas} jornadas',
                  ),
                ),
              );
              _reload();
            } else if (state is LeagueError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is LeagueLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LeagueDetailLoaded) {
              final d = state.detail;
              return Column(
                children: [
                  if (isSuperAdmin && d.fixture.isEmpty && d.teams.length >= 2)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.read<LeagueBloc>().add(
                            GenerateFixtureRequested(leagueId: widget.leagueId),
                          ),
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            'Generar fixture (${d.teams.length} equipos)',
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _FixtureTab(detail: d),
                        _StandingsTab(detail: d),
                        _ScorersTab(detail: d),
                        _TeamsTab(
                          detail: d,
                          leagueId: widget.leagueId,
                          onRegistered: _reload,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Center(
              child: FilledButton(
                onPressed: _reload,
                child: const Text('Cargar detalle'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FixtureTab extends StatelessWidget {
  final LeagueDetail detail;
  const _FixtureTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.fixture.isEmpty) {
      return const Center(
        child: Text('Sin fixture. El admin lo genera con 2+ equipos.'),
      );
    }
    final jornadas = <int, List<FixtureEntry>>{};
    for (final f in detail.fixture) {
      jornadas.putIfAbsent(f.jornada, () => []).add(f);
    }
    final keys = jornadas.keys.toList()..sort();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final j = keys[i];
        final games = jornadas[j]!;
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Jornada $j',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...games.map(
                  (g) => ListTile(
                    dense: true,
                    title: Text(
                      '${g.equipoANombre} vs ${g.equipoBNombre}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: g.jugado
                        ? Text('Final: ${g.golesA} - ${g.golesB}')
                        : Text(g.status ?? 'Pendiente'),
                    trailing: g.matchId == null
                        ? null
                        : IconButton(
                            tooltip: 'Ver partido',
                            icon: const Icon(Icons.open_in_new, size: 20),
                            onPressed: () => context.push(
                              '/matches/match_detail/${g.matchId}',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StandingsTab extends StatelessWidget {
  final LeagueDetail detail;
  const _StandingsTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.standings.isEmpty) {
      return const Center(child: Text('Sin equipos.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Equipo')),
          DataColumn(label: Text('Pts'), numeric: true),
          DataColumn(label: Text('PJ'), numeric: true),
          DataColumn(label: Text('G'), numeric: true),
          DataColumn(label: Text('E'), numeric: true),
          DataColumn(label: Text('P'), numeric: true),
          DataColumn(label: Text('GF'), numeric: true),
          DataColumn(label: Text('GC'), numeric: true),
          DataColumn(label: Text('DG'), numeric: true),
        ],
        rows: detail.standings.asMap().entries.map((e) {
          final s = e.value;
          return DataRow(
            cells: [
              DataCell(Text('${e.key + 1}')),
              DataCell(
                Text(
                  s.teamName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text('${s.points}')),
              DataCell(Text('${s.gamesPlayed}')),
              DataCell(Text('${s.wins}')),
              DataCell(Text('${s.draws}')),
              DataCell(Text('${s.losses}')),
              DataCell(Text('${s.goalsFor}')),
              DataCell(Text('${s.goalsAgainst}')),
              DataCell(Text('${s.goalDifference}')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ScorersTab extends StatelessWidget {
  final LeagueDetail detail;
  const _ScorersTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.scorers.isEmpty) {
      return const Center(child: Text('Sin goles registrados todavía.'));
    }
    return ListView.builder(
      itemCount: detail.scorers.length,
      itemBuilder: (context, i) {
        final s = detail.scorers[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text(
            s.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Chip(label: Text('${s.goles} ⚽')),
        );
      },
    );
  }
}

class _TeamsTab extends StatelessWidget {
  final LeagueDetail detail;
  final String leagueId;
  final VoidCallback onRegistered;
  const _TeamsTab({
    required this.detail,
    required this.leagueId,
    required this.onRegistered,
  });

  @override
  Widget build(BuildContext context) {
    if (detail.teams.isEmpty) {
      return const Center(child: Text('Sin equipos inscritos.'));
    }
    return ListView.builder(
      itemCount: detail.teams.length,
      itemBuilder: (context, i) {
        final t = detail.teams[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.shield, color: Colors.teal),
            title: Text(
              t.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${t.plantilla.length} jugadores en plantilla'),
          ),
        );
      },
    );
  }
}
