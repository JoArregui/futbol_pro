import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/field_bloc.dart';

/// Mis reservas con estado de seña y botón de pago.
class MisReservasPage extends StatefulWidget {
  const MisReservasPage({super.key});

  @override
  State<MisReservasPage> createState() => _MisReservasPageState();
}

class _MisReservasPageState extends State<MisReservasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FieldBloc>().add(const MisReservasRequested()),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'senada':
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas'), centerTitle: true),
      body: BlocConsumer<FieldBloc, FieldState>(
        listener: (context, state) {
          if (state is PagoConfirmado) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Seña pagada. Cancha asegurada.'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<FieldBloc>().add(const MisReservasRequested());
          } else if (state is FieldError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FieldLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MisReservasLoaded) {
            if (state.reservas.isEmpty) {
              return const Center(child: Text('Aún no tienes reservas.'));
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<FieldBloc>().add(const MisReservasRequested()),
              child: ListView.builder(
                itemCount: state.reservas.length,
                itemBuilder: (context, i) {
                  final r = state.reservas[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.stadium,
                        color: _estadoColor(r.estado),
                      ),
                      title: Text(
                        r.fieldName.isNotEmpty
                            ? r.fieldName
                            : 'Cancha ${r.fieldId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Total \$${r.total.toStringAsFixed(2)} • Seña \$${r.sena.toStringAsFixed(2)}\nEstado: ${r.estado}',
                      ),
                      isThreeLine: true,
                      trailing: r.senaPagada
                          ? Chip(
                              label: const Text(
                                'Señada',
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.green.shade100,
                            )
                          : (r.pagoId == null || r.providerRef == null
                                ? null
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton(
                                        onPressed: r.approvalUrl == null
                                            ? null
                                            : () async {
                                                final url = Uri.tryParse(
                                                  r.approvalUrl!,
                                                );
                                                if (url != null) {
                                                  await launchUrl(
                                                    url,
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                }
                                              },
                                        child: const Text('Abrir PayPal'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            context.read<FieldBloc>().add(
                                              ConfirmPagoRequested(
                                                pagoId: r.pagoId!,
                                                orderId: r.providerRef!,
                                                reservaId: r.reservaId,
                                              ),
                                            ),
                                        child: const Text('Verificar'),
                                      ),
                                    ],
                                  )),
                    ),
                  );
                },
              ),
            );
          }
          return Center(
            child: FilledButton(
              onPressed: () =>
                  context.read<FieldBloc>().add(const MisReservasRequested()),
              child: const Text('Cargar reservas'),
            ),
          );
        },
      ),
    );
  }
}
