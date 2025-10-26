import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Importaciones requeridas
import '../../../../core/injection_container.dart';
import '../../domain/entities/standing.dart';

// ✅ CORRECCIÓN: Importar el BLoC y sus clases (Eventos y Estados)
// ASUME que esta es la ruta correcta a tu archivo league_bloc.dart
import '../bloc/league_bloc.dart';

class StandingsPage extends StatelessWidget {
  final String currentLeagueId; // Ejemplo: 'liga_principal_2025'

  const StandingsPage({super.key, required this.currentLeagueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // La variable 'sl' debe estar importada desde 'injection_container.dart'
      create: (_) => sl<LeagueBloc>()
        ..add(
          GetStandingsRequested(leagueId: currentLeagueId),
        ), // Dispara el evento al inicio
      child: Scaffold(
        appBar: AppBar(title: const Text('Tabla de Clasificación 🏆')),
        body: BlocBuilder<LeagueBloc, LeagueState>(
          builder: (context, state) {
            if (state is LeagueLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LeagueLoadSuccess) {
              // El acceso a 'state.standings' es seguro dentro del 'if'
              return StandingsTable(standings: state.standings);
            }
            if (state is LeagueError) {
              // El acceso a 'state.message' es seguro dentro del 'if'
              return Center(
                child: Text('Error al cargar la tabla: ${state.message}'),
              );
            }
            // Estado inicial o desconocido
            return const Center(child: Text('Datos no disponibles.'));
          },
        ),
      ),
    );
  }
}

class StandingsTable extends StatelessWidget {
  final List<Standing> standings;

  const StandingsTable({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    // Ordenar por Puntos (descendente) antes de construir la tabla
    final sortedStandings = List<Standing>.from(standings)
      ..sort((a, b) => b.points.compareTo(a.points));

    // DataRow para la cabecera
    const columns = [
      DataColumn(label: Text('#')),
      DataColumn(
        label: Text('Equipo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      DataColumn(label: Text('PJ')), // Partidos Jugados
      DataColumn(label: Text('PG')), // Partidos Ganados
      DataColumn(label: Text('PE')), // Partidos Empatados
      DataColumn(label: Text('PP')), // Partidos Perdidos
      DataColumn(label: Text('GF')), // Goles a Favor
      DataColumn(label: Text('GC')), // Goles en Contra
      DataColumn(label: Text('DG')), // Diferencia de Goles
      DataColumn(
        label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold)),
      ), // Puntos
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: sortedStandings.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final s = entry.value;
          return DataRow(
            cells: [
              DataCell(Text(index.toString())),
              DataCell(
                Text(s.teamName, style: TextStyle(fontWeight: FontWeight.w600)),
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
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
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
