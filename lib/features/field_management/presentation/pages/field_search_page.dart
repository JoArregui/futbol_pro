import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection_container.dart';
import '../bloc/field_bloc.dart';

class FieldSearchPage extends StatelessWidget {
  const FieldSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Provee el FieldBloc a la página
    return BlocProvider(
      create: (_) => sl<FieldBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Buscar Campos Disponibles 🏟️')),
        body: Column(
          children: [
            // Widget que dispara la búsqueda al presionar un botón
            SearchControls(
              onSearch: (start, end) {
                context.read<FieldBloc>().add(
                  GetAvailableFieldsEvent(startTime: start, endTime: end),
                );
              },
            ),
            // 2. Escucha y construye la lista de resultados
            Expanded(
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
                          // Acción: Al presionar, inicia el flujo de reserva
                          onTap: () {
                            // Aquí se dispararía un ReserveFieldEvent
                          },
                        );
                      },
                    );
                  }
                  if (state is FieldError) {
                    return Center(child: Text('Error: ${state.message}'));
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
      ),
    );
  }
}

// Widget ficticio para simular la entrada de fecha/hora
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
          final end = DateTime(now.year, now.month, now.day, 20, 0); // 8:00 PM
          onSearch(start, end);
        },
        child: const Text('Buscar Campos (18:00 - 20:00)'),
      ),
    );
  }
}
