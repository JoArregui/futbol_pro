import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection_container.dart';
import '../bloc/match_bloc.dart';
import '../bloc/widgets/join_match_button.dart'; 

class MatchDetailPage extends StatelessWidget {
  final String matchId;

  const MatchDetailPage({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    // 1. Usamos BlocProvider.value si ya se creó, o BlocProvider para crear una instancia.
    // Usamos GetIt (sl) para obtener la instancia de MatchBloc
    return BlocProvider(
      // Usamos el Service Locator (sl) para obtener el MatchBloc
      create: (_) => sl<MatchBloc>(), 
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalles del Amistoso')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Información del Partido...'),
              const SizedBox(height: 30),
              // 2. Aquí es donde se conecta el widget del botón
              JoinMatchButton(matchId: matchId),
            ],
          ),
        ),
      ),
    );
  }
}