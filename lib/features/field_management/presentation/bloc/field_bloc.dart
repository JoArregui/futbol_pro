import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/confirm_pago.dart';
import '../../domain/usecases/get_available_fields.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/field.dart';
import '../../domain/usecases/get_mis_reservas.dart';
import '../../domain/usecases/reserve_field.dart';

part 'field_event.dart';
part 'field_state.dart';

class FieldBloc extends Bloc<FieldEvent, FieldState> {
  final GetAvailableFields getAvailableFields;
  final ReserveField reserveField;
  final ConfirmPago? confirmPago;
  final GetMisReservas? getMisReservas;

  FieldBloc({
    required this.getAvailableFields,
    required this.reserveField,
    this.confirmPago,
    this.getMisReservas,
  }) : super(FieldInitial()) {
    on<GetAvailableFieldsEvent>(_onGetAvailableFields);
    on<ReserveFieldRequested>(_onReserveFieldRequested);
    on<ConfirmPagoRequested>(_onConfirmPago);
    on<MisReservasRequested>(_onMisReservas);
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
    emit(FieldLoading());

    final res = await reserveField(
      ReserveFieldParams(
        fieldId: event.fieldId,
        startTime: event.startTime,
        endTime: event.endTime,
        userId: event.userId,
        paymentMethod: event.paymentMethod,
      ),
    );

    res.fold(
      (failure) => emit(FieldError(message: failure.errorMessage)),
      (booking) => emit(FieldReservedSuccess(booking: booking)),
    );
  }

  Future<void> _onConfirmPago(
    ConfirmPagoRequested event,
    Emitter<FieldState> emit,
  ) async {
    if (confirmPago == null) {
      emit(const FieldError(message: 'Pagos no disponibles.'));
      return;
    }
    emit(FieldLoading());
    final res = await confirmPago!(
      ConfirmPagoParams(pagoId: event.pagoId, orderId: event.orderId),
    );
    res.fold(
      (f) => emit(FieldError(message: f.errorMessage)),
      (_) => emit(PagoConfirmado(reservaId: event.reservaId)),
    );
  }

  Future<void> _onMisReservas(
    MisReservasRequested event,
    Emitter<FieldState> emit,
  ) async {
    if (getMisReservas == null) {
      emit(const FieldError(message: 'Reservas no disponibles.'));
      return;
    }
    emit(FieldLoading());
    final res = await getMisReservas!(NoParams());
    res.fold(
      (f) => emit(FieldError(message: f.errorMessage)),
      (list) => emit(MisReservasLoaded(reservas: list)),
    );
  }
}
