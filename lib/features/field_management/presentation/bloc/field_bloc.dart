import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/usecases/get_available_fields.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/field.dart';
import '../../domain/usecases/reserve_field.dart';

part 'field_event.dart';
part 'field_state.dart';

class FieldBloc extends Bloc<FieldEvent, FieldState> {
  final GetAvailableFields getAvailableFields;
  final ReserveField reserveField;

  FieldBloc({required this.getAvailableFields, required this.reserveField})
    : super(FieldInitial()) {
    on<GetAvailableFieldsEvent>(_onGetAvailableFields);
    on<ReserveFieldRequested>(_onReserveFieldRequested);
  }

  // Se usará la extensión de Failure (failure.errorMessage) en lugar de una función auxiliar
  // para mantener la lógica de mapeo donde debe estar.

  Future<void> _onGetAvailableFields(
    GetAvailableFieldsEvent event,
    Emitter<FieldState> emit,
  ) async {
    emit(FieldLoading());

    final failureOrFields = await getAvailableFields(
      AvailableFieldParams(startTime: event.startTime, endTime: event.endTime),
    );

    failureOrFields.fold(
      (failure) {
        // ✅ CORRECCIÓN: Usar la extensión 'errorMessage' que definiste en failures.dart
        emit(FieldError(message: failure.errorMessage));
      },
      (fields) {
        if (fields.isEmpty) {
          emit(FieldNoData());
        } else {
          emit(FieldLoadSuccess(fields: fields));
        }
      },
    );
  }

  // ✅ CORRECCIÓN: Esta función ahora está DENTRO de la clase FieldBloc
  Future<void> _onReserveFieldRequested(
    ReserveFieldRequested event,
    Emitter<FieldState> emit,
  ) async {
    emit(
      FieldLoading(),
    ); // Muestra un spinner mientras se procesa el pago/reserva

    final failureOrSuccess = await reserveField(
      ReserveFieldParams(
        fieldId: event.fieldId,
        startTime: event.startTime,
        endTime: event.endTime,
        userId: event.userId,
        totalCost: event.totalCost,
      ),
    );

    failureOrSuccess.fold(
      // ✅ CORRECCIÓN: Usar la extensión 'errorMessage' que definiste en failures.dart
      (failure) => emit(FieldError(message: failure.errorMessage)),
      (isSuccess) {
        if (isSuccess) {
          emit(const FieldReservedSuccess(fieldName: "Campo Reservado"));

          // ... Lógica de Negocio Crucial (mantener esto como comentario por ahora)
        } else {
          // Si el backend devuelve 'false' (éxito, pero la lógica de reserva falló)
          emit(
            const FieldError(
              message: "La reserva fue rechazada por el servidor.",
            ),
          );
        }
      },
    );
  }
}

// ✅ CORRECCIÓN: La función auxiliar 'mapFailureToMessage' ha sido ELIMINADA.
// Su funcionalidad la reemplaza el getter 'errorMessage' en la extensión de Failure.
