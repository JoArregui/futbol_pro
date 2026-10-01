import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Importar go_router para navegación segura
import '../../../../core/injection_container.dart';
import '../../domain/entities/standing.dart';
import '../../domain/entities/tournament.dart';
import '../bloc/league_bloc.dart';

// ==============================================================
// STANDINGS PAGE — con selector de liga (antes pedía un ID quemado)
// ==============================================================

class StandingsPage extends StatelessWidget {
  final String? currentLeagueId;

  const StandingsPage({super.key, this.currentLeagueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LeagueBloc>()..add(const GetTournamentsRequested()),
      child: _StandingsView(initialLeagueId: currentLeagueId),
    );
  }
}

class _StandingsView extends StatefulWidget {
  final String? initialLeagueId;
  const _StandingsView({required this.initialLeagueId});

  @override
  State<_StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<_StandingsView> {
  String? _selectedId;
  List<Tournament> _tournaments = const [];

  void _load(String id) {
    setState(() => _selectedId = id);
    context.read<LeagueBloc>().add(GetStandingsRequested(leagueId: id));
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Tabla de Clasificación 🏆',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<LeagueBloc, LeagueState>(
        listener: (context, state) {
          if (!mounted) return;
          // Conserva la lista para el selector y auto-selecciona la primera.
          if (state is TournamentsLoaded) {
            setState(() => _tournaments = state.tournaments);
            if (_selectedId == null && state.tournaments.isNotEmpty) {
              final initial = widget.initialLeagueId;
              final ids = state.tournaments.map((t) => t.id).toSet();
              if (initial != null && ids.contains(initial)) {
                _load(initial);
              } else {
                _load(state.tournaments.first.id);
              }
            }
          }
        },
        builder: (context, state) {
          if (state is LeagueLoading && _selectedId == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TournamentsLoaded && _selectedId == null) {
            if (state.tournaments.isEmpty) {
              return _EmptyLeagues(
                onRetry: () => context.read<LeagueBloc>().add(
                  const GetTournamentsRequested(),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LeagueError && _selectedId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.read<LeagueBloc>().add(
                        const GetTournamentsRequested(),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _StandingsBody(
            selectedId: _selectedId,
            tournaments: _tournaments,
            state: state,
            onSelect: _load,
          );
        },
      ),
    );
  }
}

class _StandingsBody extends StatelessWidget {
  final String? selectedId;
  final List<Tournament> tournaments;
  final LeagueState state;
  final ValueChanged<String> onSelect;

  const _StandingsBody({
    required this.selectedId,
    required this.tournaments,
    required this.state,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (tournaments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                labelText: 'Liga',
                border: OutlineInputBorder(),
              ),
              items: tournaments
                  .map(
                    (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onSelect(v);
              },
            ),
          ),
        Expanded(
          child: Builder(
            builder: (context) {
              final currentState = state;
              if (currentState is LeagueLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (currentState is LeagueLoadSuccess) {
                if (currentState.standings.isEmpty) {
                  return const Center(
                    child: Text('Sin equipos en esta liga todavía.'),
                  );
                }
                return StandingsTable(standings: currentState.standings);
              }
              if (currentState is LeagueError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error al cargar la tabla: ${currentState.message}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                );
              }
              if (currentState is TournamentsLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              return const Center(
                child: Text('Selecciona una liga para ver los datos.'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyLeagues extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyLeagues({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay ligas todavía.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Un superadmin puede crear una desde Torneos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/tournaments'),
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('Abrir Torneos'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// STANDINGS TABLE WIDGET
// ==============================================================

class StandingsTable extends StatelessWidget {
  final List<Standing> standings;

  const StandingsTable({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    final sortedStandings = List<Standing>.from(standings)
      ..sort((a, b) => b.points.compareTo(a.points));

    const columns = [
      DataColumn(label: Text('#')),
      DataColumn(
        label: Text('Equipo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      DataColumn(label: Text('PJ')),
      DataColumn(label: Text('PG')),
      DataColumn(label: Text('PE')),
      DataColumn(label: Text('PP')),
      DataColumn(label: Text('GF')),
      DataColumn(label: Text('GC')),
      DataColumn(label: Text('DG')),
      DataColumn(
        label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMaxHeight: 50,
        headingRowHeight: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        columnSpacing: 16,
        columns: columns,
        rows: sortedStandings.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final s = entry.value;

          final isTopThree = index <= 3;

          return DataRow(
            color: WidgetStateProperty.resolveWith<Color>((
              Set<WidgetState> states,
            ) {
              if (isTopThree) {
                return Colors.blue.shade50;
              }
              return Colors.transparent;
            }),
            cells: [
              DataCell(
                Text(
                  index.toString(),
                  style: TextStyle(
                    fontWeight: isTopThree
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              DataCell(
                Text(
                  s.teamName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(s.gamesPlayed.toString())),
              DataCell(Text(s.wins.toString())),
              DataCell(Text(s.draws.toString())),
              DataCell(Text(s.losses.toString())),
              DataCell(Text(s.goalsFor.toString())),
              DataCell(Text(s.goalsAgainst.toString())),
              DataCell(Text(s.goalDifference.toString())),
              DataCell(
                Text(
                  s.points.toString(),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
