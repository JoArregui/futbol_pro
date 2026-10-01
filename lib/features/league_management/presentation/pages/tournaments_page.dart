import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/league_bloc.dart';

/// Torneos/ligas: ver lista e inscribir un equipo completo.
class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) {
          context.read<LeagueBloc>().add(const GetTournamentsRequested());
        }
      },
    );
  }

  Future<void> _register(String leagueId) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inscribir equipo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              hintText: 'Nombre del equipo',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, ctrl.text.trim()),
              child: const Text('Inscribir')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    if (!mounted) return;
    context
        .read<LeagueBloc>()
        .add(RegisterTeamRequested(leagueId: leagueId, teamName: name));
  }

  Future<void> _createLeague() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva liga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    hintText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                    hintText: 'Descripción',
                    border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                    'nombre': nameCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                  }),
              child: const Text('Crear')),
        ],
      ),
    );
    nameCtrl.dispose();
    descCtrl.dispose();
    if (data == null || !mounted) {
      return;
    }
    if ((data['nombre'] as String).isEmpty) {
      return;
    }
    context.read<LeagueBloc>().add(CreateLeagueRequested(
        nombre: data['nombre'] as String,
        descripcion: data['descripcion'] as String));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isSuperAdmin =
        authState is AuthAuthenticated && authState.isSuperAdmin;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Torneos y ligas'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: _createLeague,
              icon: const Icon(Icons.add),
              label: const Text('Liga'),
            )
          : null,
      body: BlocConsumer<LeagueBloc, LeagueState>(
        listener: (context, state) {
          if (state is TeamRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Equipo inscrito correctamente'),
                  backgroundColor: Colors.green),
            );
            context.read<LeagueBloc>().add(const GetTournamentsRequested());
          } else if (state is LeagueCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Liga "${state.league.name}" creada')),
            );
            context.read<LeagueBloc>().add(const GetTournamentsRequested());
          } else if (state is LeagueError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is LeagueLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TournamentsLoaded) {
            if (state.tournaments.isEmpty) {
              return const Center(child: Text('No hay torneos abiertos.'));
            }
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<LeagueBloc>()
                  .add(const GetTournamentsRequested()),
              child: ListView.builder(
                itemCount: state.tournaments.length,
                itemBuilder: (context, i) {
                  final t = state.tournaments[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events,
                          color: Colors.amber),
                      title: Text(t.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${t.description}\nInicio: ${DateFormat('dd/MM/yyyy').format(t.startDate)} — ${t.registeredTeams}/${t.maxTeams} equipos',
                      ),
                      isThreeLine: true,
                      trailing: t.isOpen
                          ? FilledButton(
                              onPressed: () => _register(t.id),
                              child: const Text('Inscribir'),
                            )
                          : const Chip(label: Text('Lleno')),
                      onTap: () => context
                          .push(
                              '/tournaments/${t.id}?name=${Uri.encodeComponent(t.name)}')
                          .then((_) {
                        if (context.mounted) {
                          context
                              .read<LeagueBloc>()
                              .add(const GetTournamentsRequested());
                        }
                      }),
                    ),
                  );
                },
              ),
            );
          }
          return Center(
            child: ElevatedButton(
              onPressed: () => context
                  .read<LeagueBloc>()
                  .add(const GetTournamentsRequested()),
              child: const Text('Cargar torneos'),
            ),
          );
        },
      ),
    );
  }
}
