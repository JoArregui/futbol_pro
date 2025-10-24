import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/match_bloc.dart';


class JoinMatchButton extends StatelessWidget {
  final String matchId;

  // Asumimos que el ID del usuario actual se obtiene de alguna fuente,
  // por ejemplo, del BLoC de Autenticación (AuthBloc), pero por ahora lo simulamos.
  final String currentUserId = 'user-123-activo'; 

  const JoinMatchButton({
    super.key, 
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    // BlocListener: Se usa para manejar efectos secundarios (navegación, SnackBar, diálogos).
    return BlocListener<MatchBloc, MatchState>(
      listener: (context, state) {
        if (state is MatchScheduledSuccess) {
          // Éxito: Muestra una confirmación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ¡Te has unido al partido ${state.match.title} con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          // Opcional: Podrías navegar a otra pantalla o actualizar la lista de partidos.
        } else if (state is MatchError) {
          // Error: Muestra el mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Error al unirse: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      // BlocBuilder: Se usa para reconstruir la parte de la UI que cambia (el botón).
      child: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          // 1. Manejo del estado de Carga
          if (state is MatchLoading) {
            return const ElevatedButton(
              onPressed: null, // Deshabilitar el botón durante la carga
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            );
          }
          
          // 2. Manejo del estado de Éxito
          if (state is MatchScheduledSuccess) {
            // Si el estado muestra el partido ya actualizado y con el usuario,
            // podemos mostrar un botón diferente.
            return ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Ya estás inscrito'),
            );
          }
          
          // 3. Estado Inicial / Listo para unirse
          return ElevatedButton(
            onPressed: () {
              // Obtenemos el BLoC del contexto y disparamos el evento
              context.read<MatchBloc>().add(
                PlayerJoinsMatchEvent(
                  matchId: matchId,
                  playerId: currentUserId,
                ),
              );
            },
            child: const Text('¡Apuntarse al Amistoso!'),
          );
        },
      ),
    );
  }
}