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

  Future<void> _onReserveFieldRequested(
    ReserveFieldRequested event,
    Emitter<FieldState> emit,
  ) async {
    emit(
      FieldLoading(),
    );

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
      (failure) => emit(FieldError(message: failure.errorMessage)),
      (isSuccess) {
        if (isSuccess) {
          emit(const FieldReservedSuccess(fieldName: "Campo Reservado"));
        } else {
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
