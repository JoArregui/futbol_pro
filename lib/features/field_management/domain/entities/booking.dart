import 'package:equatable/equatable.dart';

/// Reserva con su economía: total calculado en servidor, seña y pago.
class BookingInfo extends Equatable {
  final String reservaId;
  final String fieldId;
  final String fieldName;
  final double total;
  final double sena;
  final double senaPct;
  final String estado; // pendiente | senada | confirmada | cancelada
  final String? pagoId;
  final String? providerRef;
  final String? approvalUrl;
  final String? pagoEstado;
  final String? provider;

  const BookingInfo({
    required this.reservaId,
    required this.fieldId,
    required this.fieldName,
    required this.total,
    required this.sena,
    this.senaPct = 0.2,
    required this.estado,
    this.pagoId,
    this.providerRef,
    this.approvalUrl,
    this.pagoEstado,
    this.provider,
  });

  bool get senaPagada =>
      estado == 'senada' ||
      estado == 'confirmada' ||
      pagoEstado == 'confirmado';

  factory BookingInfo.fromJson(Map<String, dynamic> json) {
    double numOf(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    return BookingInfo(
      reservaId: (json['reservaId'] ?? json['id'] ?? '').toString(),
      fieldId: (json['fieldId'] ?? '').toString(),
      fieldName: (json['fieldName'] ?? '').toString(),
      total: numOf(json['total']),
      sena: numOf(json['sena']),
      senaPct: numOf(json['senaPct'] ?? 0.2),
      estado: (json['estado'] ?? 'pendiente').toString(),
      pagoId: (json['pago'] is Map ? json['pago']['id'] : json['pagoId'])
          ?.toString(),
      providerRef: (json['pago'] is Map
              ? json['pago']['providerRef']
              : json['providerRef'])
          ?.toString(),
      approvalUrl: (json['pago'] is Map
              ? json['pago']['approvalUrl']
              : json['approvalUrl'])
          ?.toString(),
      pagoEstado: json['pagoEstado']?.toString(),
      provider:
          (json['pago'] is Map ? json['pago']['provider'] : json['provider'])
              ?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        reservaId,
        fieldId,
        fieldName,
        total,
        sena,
        senaPct,
        estado,
        pagoId,
        providerRef,
        approvalUrl,
        pagoEstado,
        provider,
      ];
}
