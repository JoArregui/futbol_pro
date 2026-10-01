import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/field_repository.dart';

class ReserveField implements UseCase<BookingInfo, ReserveFieldParams> {
  final FieldRepository repository;

  ReserveField(this.repository);

  @override
  Future<Either<Failure, BookingInfo>> call(ReserveFieldParams params) async {
    return repository.reserveField(
      fieldId: params.fieldId,
      startTime: params.startTime,
      endTime: params.endTime,
      userId: params.userId,
      paymentMethod: params.paymentMethod,
    );
  }
}

class ReserveFieldParams extends Equatable {
  final String fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final String userId;
  final String? paymentMethod;

  const ReserveFieldParams({
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
