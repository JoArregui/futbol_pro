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
  DateTime _start = DateTime.now().add(const Duration(days: 1)).copyWith(
        hour: 18,
        minute: 0,
        second: 0,
        millisecond: 0,
      );
  DateTime get _end => _start.add(const Duration(hours: 2));

  Future<void> _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (!mounted || time == null) return;
    setState(() => _start =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<String?> _choosePaymentMethod() => showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Método de pago'),
          content: const Text('Selecciona cómo quieres pagar la seña.'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext, 'paypal'),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('PayPal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, 'stripe'),
              icon: const Icon(Icons.credit_card),
              label: const Text('Tarjeta'),
            ),
          ],
        ),
      );

  Future<void> _reserve(String fieldId, String userId) async {
    final paymentMethod = await _choosePaymentMethod();
    if (!mounted || paymentMethod == null) return;
    context.read<FieldBloc>().add(ReserveFieldRequested(
          fieldId: fieldId,
          startTime: _start,
          endTime: _end,
          userId: userId,
          paymentMethod: paymentMethod,
        ));
  }

  void _showBookingSheet(BookingInfo booking) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reserva: ${booking.fieldName}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total: \$${booking.total.toStringAsFixed(2)}'),
            Text(
                'Seña (${(booking.senaPct * 100).toStringAsFixed(0)}%): \$${booking.sena.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: booking.approvalUrl == null
                    ? null
                    : () async {
                        final uri = Uri.tryParse(booking.approvalUrl!);
                        if (uri != null) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                icon: Icon(booking.provider == 'stripe'
                    ? Icons.credit_card
                    : Icons.account_balance_wallet),
                label: Text(booking.provider == 'stripe'
                    ? 'Pagar con tarjeta'
                    : 'Abrir PayPal'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: booking.pagoId == null || booking.providerRef == null
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        context.read<FieldBloc>().add(ConfirmPagoRequested(
                              pagoId: booking.pagoId!,
                              orderId: booking.providerRef!,
                              reservaId: booking.reservaId,
                            ));
                      },
                icon: const Icon(Icons.verified),
                label: const Text('Verificar pago'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
                'Después de pagar, vuelve a la aplicación y pulsa Verificar pago.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FieldBloc>(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            title: const Text('Canchas disponibles'),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<FieldBloc>(),
                      child: const MisReservasPage(),
                    ),
                  ),
                ),
                child: const Text('Mis reservas',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: BlocConsumer<FieldBloc, FieldState>(
            listener: (context, state) {
              if (state is FieldReservedSuccess) {
                _showBookingSheet(state.booking);
              } else if (state is PagoConfirmado) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Pago verificado. Cancha asegurada.'),
                    backgroundColor: Colors.green));
              } else if (state is FieldError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message), backgroundColor: Colors.red));
              }
            },
            builder: (context, state) => Column(
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
                Expanded(child: _buildResults(context, state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, FieldState state) {
    if (state is FieldLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is FieldNoData) {
      return const Center(child: Text('No hay campos libres en ese horario.'));
    }
    if (state is! FieldLoadSuccess || state.fields.isEmpty) {
      return const Center(child: Text('Elige fecha y pulsa Ver.'));
    }
    final auth = context.read<AuthBloc>().state;
    final userId = auth is AuthAuthenticated ? auth.userId : 'demo';
    return ListView.builder(
      itemCount: state.fields.length,
      itemBuilder: (context, index) {
        final field = state.fields[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.stadium, color: Colors.teal),
            title: Text(field.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Tarifa: \$${field.hourlyRate}/h\n${DateFormat('dd/MM HH:mm').format(_start)} - ${DateFormat('HH:mm').format(_end)}'),
            isThreeLine: true,
            trailing: FilledButton(
                onPressed: () => _reserve(field.id, userId),
                child: const Text('Reservar')),
          ),
        );
      },
    );
  }
}
