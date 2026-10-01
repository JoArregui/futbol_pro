import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/booking.dart';
import '../entities/field.dart';

abstract class FieldRepository {
  Future<Either<Failure, List<Field>>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  });

  Future<Either<Failure, BookingInfo>> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    String? paymentMethod,
  });

  Future<Either<Failure, bool>> confirmPago({
    required String pagoId,
    required String orderId,
  });

  Future<Either<Failure, List<BookingInfo>>> misReservas();
}
