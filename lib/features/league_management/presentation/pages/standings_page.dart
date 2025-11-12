import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection_container.dart';
import '../../domain/entities/standing.dart';
import '../bloc/league_bloc.dart';

// ==============================================================
// STANDINGS PAGE
// ==============================================================

class StandingsPage extends StatelessWidget {
  final String currentLeagueId;

  const StandingsPage({super.key, required this.currentLeagueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LeagueBloc>()
        ..add(
          GetStandingsRequested(leagueId: currentLeagueId),
        ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tabla de Clasificación 🏆',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: true,
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<LeagueBloc, LeagueState>(
          builder: (context, state) {
            if (state is LeagueLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LeagueLoadSuccess) {
              return StandingsTable(standings: state.standings);
            }
            if (state is LeagueError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar la tabla: ${state.message}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              );
            }

            return const Center(
              child: Text('Selecciona una liga para ver los datos.'),
            );
          },
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
            color: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (isTopThree) {
                  return Colors.blue.shade50;
                }
                return Colors.transparent;
              },
            ),
            cells: [
              DataCell(
                Text(
                  index.toString(),
                  style: TextStyle(
                    fontWeight:
                        isTopThree ? FontWeight.bold : FontWeight.normal,
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
