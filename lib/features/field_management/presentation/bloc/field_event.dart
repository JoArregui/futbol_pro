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

// Evento futuro: cuando el usuario selecciona un campo y decide reservarlo
// class ReserveFieldEvent extends FieldEvent { ... }
class ReserveFieldRequested extends FieldEvent {
  final String fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final String userId; // Tomado del AuthBloc/Usuario actual
  final double totalCost;

  const ReserveFieldRequested({
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.userId,
    required this.totalCost,
  });

  @override
  List<Object> get props => [fieldId, startTime, endTime, userId, totalCost];
}