import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/field_repository.dart';

// El éxito de esta operación puede ser simplemente 'true' o el ID de la reserva.
// Usaremos 'true' por simplicidad.
class ReserveField implements UseCase<bool, ReserveFieldParams> {
  final FieldRepository repository;

  ReserveField(this.repository);

  @override
  Future<Either<Failure, bool>> call(ReserveFieldParams params) async {
    // Aquí, la lógica de negocio podría incluir:
    // 1. Verificar si el usuario tiene fondos/créditos suficientes (si tienes ese módulo).
    // 2. Realizar un chequeo de disponibilidad en el último minuto (el 'backend' debe hacerlo).

    return await repository.reserveField(
      fieldId: params.fieldId,
      startTime: params.startTime,
      endTime: params.endTime,
      userId: params.userId,
      totalCost: params.totalCost,
    );
  }
}

class ReserveFieldParams extends Equatable {
  final String fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final String userId;
  final double totalCost;

  const ReserveFieldParams({
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.userId,
    required this.totalCost,
  });

  @override
  List<Object> get props => [fieldId, startTime, endTime, userId, totalCost];
}
