import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha
import '../../domain/entities/match.dart'; // Importa la entidad Match
import '../bloc/match_bloc.dart'; // Asume que MatchBloc está disponible

// Necesitas definir un nuevo estado y evento en match_event.dart y match_state.dart:
// - GetUpcomingMatchesEvent (para disparar la carga)
// - MatchesListLoaded (para contener la List<Match>)

class MatchListPage extends StatelessWidget {
  const MatchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 Disparar la carga de partidos al construir la página
    // Asume que tienes un evento GetUpcomingMatchesEvent
    context.read<MatchBloc>().add(const GetUpcomingMatchesEvent()); 

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
        title: const Text('Partidos Programados'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
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
              return const Center(
                child: Text('No hay partidos programados.', 
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              );
            }

            return ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final String timeFormatted = DateFormat('dd/MM HH:mm').format(match.scheduledTime);
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.sports_soccer, color: Colors.teal),
                    title: Text(
                      // Asumo que tu entidad Match tiene un campo 'title'
                      match.title, 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Fecha: $timeFormatted - Campo: ${match.fieldId}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navegar al detalle del partido
                      context.go('/matches/match_detail/${match.id}');
                    },
                  ),
                );
              },
            );
          }
          
          // Estado por defecto (MatchInitial, o si MatchScheduledSuccess se ha disparado)
          return const Center(child: Text('Cargando agenda...'));
        },
      ),
    );
  }
}