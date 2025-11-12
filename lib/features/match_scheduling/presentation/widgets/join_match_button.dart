import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/match_bloc.dart';

class JoinMatchButton extends StatelessWidget {
  final String matchId;

  final String currentUserId = 'user-123-activo';

  const JoinMatchButton({
    super.key,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchBloc, MatchState>(
      listener: (context, state) {
        if (state is MatchScheduledSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🎉 ¡Te has unido al partido ${state.match.title} con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is MatchError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Error al unirse: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchLoading) {
            return const ElevatedButton(
              onPressed: null,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            );
          }

          if (state is MatchScheduledSuccess) {
            return ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Ya estás inscrito'),
            );
          }

          return ElevatedButton(
            onPressed: () {
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