import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Partido'),
        centerTitle: true,
      ),
      body: BlocBuilder<MatchDetailBloc, MatchDetailState>(
        builder: (context, state) {
          if (state is MatchDetailLoading) {
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}
