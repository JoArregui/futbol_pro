import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/field.dart';

abstract class FieldRepository {
  /// Obtiene una lista de campos disponibles en un rango de tiempo.
  Future<Either<Failure, List<Field>>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Reserva o alquila un campo.
  Future<Either<Failure, bool>> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    required double totalCost,
  });
}