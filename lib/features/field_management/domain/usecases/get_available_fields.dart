import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/field.dart';
import '../repositories/field_repository.dart';

class GetAvailableFields implements UseCase<List<Field>, AvailableFieldParams> {
  final FieldRepository repository;

  GetAvailableFields(this.repository);

  @override
  Future<Either<Failure, List<Field>>> call(AvailableFieldParams params) async {
    // Lógica de negocio si fuera necesaria (ej: verificar permisos)
    return await repository.getAvailableFields(
      startTime: params.startTime,
      endTime: params.endTime,
    );
  }
}

class AvailableFieldParams extends Equatable {
  final DateTime startTime;
  final DateTime endTime;

  const AvailableFieldParams({required this.startTime, required this.endTime});

  @override
  List<Object> get props => [startTime, endTime];
}
