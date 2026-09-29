part of 'field_bloc.dart';

abstract class FieldState extends Equatable {
  const FieldState();

  @override
  List<Object> get props => [];
}

class FieldInitial extends FieldState {}

class FieldLoading extends FieldState {}

class FieldLoadSuccess extends FieldState {
  final List<Field> fields;

  const FieldLoadSuccess({required this.fields});

  @override
  List<Object> get props => [fields];
}

class FieldError extends FieldState {
  final String message;

  const FieldError({required this.message});

  @override
  List<Object> get props => [message];
}

class FieldNoData extends FieldState {}

class FieldReservedSuccess extends FieldState {
  final BookingInfo booking;

  String get fieldName => booking.fieldName;

  const FieldReservedSuccess({required this.booking});

  @override
  List<Object> get props => [booking];
}

class PagoConfirmado extends FieldState {
  final String reservaId;

  const PagoConfirmado({required this.reservaId});

  @override
  List<Object> get props => [reservaId];
}

class MisReservasLoaded extends FieldState {
  final List<BookingInfo> reservas;

  const MisReservasLoaded({required this.reservas});

  @override
  List<Object> get props => [reservas];
}
