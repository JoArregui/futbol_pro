import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/booking.dart';
import '../bloc/field_bloc.dart';
import 'mis_reservas_page.dart';

class FieldSearchPage extends StatefulWidget {
  const FieldSearchPage({super.key});

  @override
  State<FieldSearchPage> createState() => _FieldSearchPageState();
}

class _FieldSearchPageState extends State<FieldSearchPage> {
  DateTime _start =
      DateTime.now().add(const Duration(days: 1)).copyWith(hour: 18, minute: 0);
  DateTime get _end => _start.add(const Duration(hours: 2));

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() =>
        _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  /// Hoja con la economía: total servidor + seña a pagar.
  void _showBookingSheet(BuildContext context, BookingInfo booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reserva: ${booking.fieldName}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total: \$${booking.total.toStringAsFixed(2)}'),
            Text(
                'Seña (${(booking.senaPct * 100).toStringAsFixed(0)}%): \$${booking.sena.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Estado: ${booking.estado}',
                style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: booking.approvalUrl == null
                    ? null
                    : () async {
                        final url = Uri.tryParse(booking.approvalUrl!);
                        if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                icon: const Icon(Icons.payments),
                label: const Text('Abrir PayPal'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: booking.pagoId == null || booking.providerRef == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        context.read<FieldBloc>().add(ConfirmPagoRequested(
                            pagoId: booking.pagoId!,
                            orderId: booking.providerRef!,
                            reservaId: booking.reservaId));
                      },
                icon: const Icon(Icons.verified),
                label: const Text('Ya he aprobado el pago'),
              ),
            ),
            const Text(
              'Tras aprobar el pago, vuelve a la aplicación y verifica la orden.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

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
              title: const Text('Canchas disponibles'),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                              value: context.read<FieldBloc>(),
                              child: const MisReservasPage(),
                            ))),
                  child: const Text('Mis reservas',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pick,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('dd/MM HH:mm').format(_start)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => context.read<FieldBloc>().add(
                            GetAvailableFieldsEvent(
                                startTime: _start, endTime: _end)),
                        icon: const Icon(Icons.search),
                        label: const Text('Ver'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocConsumer<FieldBloc, FieldState>(
                    listener: (context, state) {
                      if (state is FieldReservedSuccess) {
                        _showBookingSheet(context, state.booking);
                      } else if (state is PagoConfirmado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Seña pagada. Cancha asegurada.'),
                              backgroundColor: Colors.green),
                        );
                      } else if (state is FieldError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is FieldLoading) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (state is FieldLoadSuccess) {
                        if (state.fields.isEmpty) {
                          return const Center(
                              child: Text('Sin campos libres en ese horario.'));
                        }
                        return ListView.builder(
                          itemCount: state.fields.length,
                          itemBuilder: (context, index) {
                            final field = state.fields[index];
                            final auth = context.read<AuthBloc>().state;
                            final uid = auth is AuthAuthenticated
                                ? auth.userId
                                : 'demo';
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.stadium,
                                    color: Colors.teal),
                                title: Text(field.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Tarifa: \$${field.hourlyRate}/h - ${field.type.name}\n${DateFormat('dd/MM HH:mm').format(_start)} - ${DateFormat('HH:mm').format(_end)}',
                                ),
                                isThreeLine: true,
                                trailing: FilledButton(
                                  onPressed: () =>
                                      context.read<FieldBloc>().add(
                                            ReserveFieldRequested(
                                              fieldId: field.id,
                                              startTime: _start,
                                              endTime: _end,
                                              userId: uid,
                                            ),
                                          ),
                                  child: const Text('Reservar'),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      if (state is FieldNoData) {
                        return const Center(
                          child: Text(
                            'No hay campos disponibles en ese horario.',
                          ),
                        );
                      }
                      return const Center(
                        child: Text('Elige fecha y pulsa Ver.'),
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
