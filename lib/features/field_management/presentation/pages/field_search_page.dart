import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/injection_container.dart';
import '../bloc/field_bloc.dart';

class FieldSearchPage extends StatelessWidget {
  const FieldSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Envolvemos la página completa en el BlocProvider.
    return BlocProvider(
      create: (_) => sl<FieldBloc>(),
      child: Builder(
        // 2. Usamos Builder para obtener un *nuevo* contexto (contexto hijo)
        // que ahora está *debajo* del BlocProvider.
        builder: (context) {
          // 3. Este nuevo contexto (context) es válido para leer el FieldBloc.
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
              title: const Text('Buscar Campos Disponibles 🏟️'),
              centerTitle: true,
            ),
            body: Column(
              children: [
                SearchControls(
                  // 4. La lógica de lectura se ejecuta ahora con el contexto correcto.
                  onSearch: (start, end) {
                    context.read<FieldBloc>().add(
                          GetAvailableFieldsEvent(
                              startTime: start, endTime: end),
                        );
                  },
                ),
                Expanded(
                  // El BlocBuilder también está por debajo del Provider y funciona bien.
                  child: BlocBuilder<FieldBloc, FieldState>(
                    builder: (context, state) {
                      if (state is FieldLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is FieldLoadSuccess) {
                        return ListView.builder(
                          itemCount: state.fields.length,
                          itemBuilder: (context, index) {
                            final field = state.fields[index];
                            return ListTile(
                              title: Text(field.name),
                              subtitle: Text(
                                'Tarifa: \$${field.hourlyRate}/hr. Tipo: ${field.type.name}',
                              ),
                              onTap: () {},
                            );
                          },
                        );
                      }
                      if (state is FieldError) {
                        return Center(
                            child: Text('Error: ${state.message}'));
                      }
                      if (state is FieldNoData) {
                        return const Center(
                          child: Text(
                            'No hay campos disponibles en ese horario. 😔',
                          ),
                        );
                      }
                      return const Center(
                        child: Text('Selecciona una hora para buscar.'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget ficticio para simular la entrada de fecha/hora (sin cambios necesarios)
class SearchControls extends StatelessWidget {
  final Function(DateTime, DateTime) onSearch;
  const SearchControls({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          // Valores simulados para la búsqueda
          final now = DateTime.now();
          final start = DateTime(
            now.year,
            now.month,
            now.day,
            18,
            0,
          ); // 6:00 PM
          final end =
              DateTime(now.year, now.month, now.day, 20, 0); // 8:00 PM
          onSearch(start, end);
        },
        child: const Text('Buscar Campos (18:00 - 20:00)'),
      ),
    );
  }
}