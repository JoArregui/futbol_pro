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

// Estado para cuando no hay campos disponibles, diferenciado del error
class FieldNoData extends FieldState {}

// Estado para la reserva exitosa
class FieldReservedSuccess extends FieldState {
  final String fieldName;

  const FieldReservedSuccess({required this.fieldName});

  @override
  List<Object> get props => [fieldName];
}