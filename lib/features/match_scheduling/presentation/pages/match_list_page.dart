import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha
import '../../domain/entities/match.dart'; // Importa la entidad Match
import '../bloc/match_bloc.dart'; // Asume que MatchBloc está disponible

// Necesitas definir un nuevo estado y evento en match_event.dart y match_state.dart:
// - GetUpcomingMatchesEvent (para disparar la carga)
// - MatchesListLoaded (para contener la List<Match>)

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  @override
  void initState() {
    super.initState();
    // Carga única (antes se disparaba en cada build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MatchBloc>().add(const GetUpcomingMatchesEvent());
      }
    });
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
        title: const Text('Partidos'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Torneos',
            icon: const Icon(Icons.emoji_events),
            onPressed: () => context.push('/tournaments'),
          ),
          IconButton(
            tooltip: 'Canchas',
            icon: const Icon(Icons.stadium),
            onPressed: () => context.push('/fields'),
          ),
        ],
      ),
      // 🟢 Implementación del BlocBuilder para manejar estados
      body: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MatchError) {
            return Center(
              child: Text('Error al cargar partidos: ${state.message}'),
            );
          }

          // ⚠️ Asumo que tienes un estado MatchesListLoaded que contiene List<Match>
          // Si no existe, debes implementarlo en match_state.dart y match_bloc.dart.
          // El estado MatchLoaded es para un solo partido, no para la lista.
          if (state is MatchesListLoaded) {
            final List<Match> matches = state.matches;

            if (matches.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_soccer,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No hay partidos programados.',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Crea el primero y reta a tus amigos.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.push('/matches/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear amistoso'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final String timeFormatted =
                    DateFormat('dd/MM HH:mm').format(match.scheduledTime);

                return Card(
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      match.mode == MatchMode.teamVsTeam
                          ? Icons.shield
                          : Icons.group,
                      color: Colors.teal,
                    ),
                    title: Text(
                      match.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Fecha: $timeFormatted - Campo: ${match.fieldId}'
                      '${match.needsReferee ? ' - con árbitro' : ''}'
                      '${match.mode == MatchMode.teamVsTeam ? ' - equipos' : ' - abierto'}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.go('/matches/match_detail/${match.id}');
                    },
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Cargando agenda...'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/matches/new'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Amistoso'),
      ),
    );
  }
}
