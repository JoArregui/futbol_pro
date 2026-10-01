part of 'field_bloc.dart';

abstract class FieldEvent extends Equatable {
  const FieldEvent();
}

class GetAvailableFieldsEvent extends FieldEvent {
  final DateTime startTime;
  final DateTime endTime;

  const GetAvailableFieldsEvent({
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object> get props => [startTime, endTime];
}

class ReserveFieldRequested extends FieldEvent {
  final String fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final String userId;
  final String? paymentMethod;

  const ReserveFieldRequested({
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.userId,
    this.paymentMethod,
  });

  @override
  List<Object?> get props =>
      [fieldId, startTime, endTime, userId, paymentMethod];
}

class ConfirmPagoRequested extends FieldEvent {
  final String pagoId;
  final String reservaId;
  final String orderId;

  const ConfirmPagoRequested({
    required this.pagoId,
    required this.reservaId,
    required this.orderId,
  });

  @override
  List<Object> get props => [pagoId, reservaId, orderId];
}

class MisReservasRequested extends FieldEvent {
  const MisReservasRequested();

  @override
  List<Object> get props => [];
}
