import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Importado para navegación segura
import '../../../../core/services/notify_topics.dart';
import '../bloc/match_detail_bloc.dart';
import '../widgets/match_detail_view.dart';

class MatchDetailPage extends StatefulWidget {
  final String matchId;

  const MatchDetailPage({
    super.key,
    required this.matchId,
  });

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  @override
  void initState() {
    super.initState();

    context
        .read<MatchDetailBloc>()
        .add(MatchDetailLoadRequested(widget.matchId));
    // Recibir avisos del partido (marcador validado, nuevos jugadores).
    NotifyTopics.joinMatch(widget.matchId);
  }

  @override
  void dispose() {
    NotifyTopics.leaveMatch(widget.matchId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 🚀 CORRECCIÓN: Usar '/home' como ruta de respaldo.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home'); // ¡CORREGIDO A /home!
            }
          },
        ),
        automaticallyImplyLeading: false, // Deshabilitar el leading automático
        title: const Text('Detalle del Partido'),
        centerTitle: true,
      ),
      body: BlocListener<MatchDetailBloc, MatchDetailState>(
        listener: (context, state) {
          if (state is MatchDetailLoaded && state.notice != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.notice!)),
            );
          }
          if (state is MatchDetailLoaded && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.redAccent),
            );
          }
        },
        child: BlocBuilder<MatchDetailBloc, MatchDetailState>(
          builder: (context, state) {
            if (state is MatchDetailLoading ||
                state is MatchDetailActionRunning) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MatchDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Error al cargar los detalles del partido.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID del Partido: ${widget.matchId}\nDetalle: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is MatchDetailLoaded) {
              return MatchDetailView(match: state.match);
            }

            return const Center(child: Text('Esperando datos del partido...'));
          },
        ),
      ),
    );
  }
}
