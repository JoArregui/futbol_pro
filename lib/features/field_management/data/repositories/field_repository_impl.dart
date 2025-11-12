import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/field.dart';
import '../../domain/repositories/field_repository.dart';
import '../datasources/field_remote_datasource.dart';

class FieldRepositoryImpl implements FieldRepository {
  final FieldRemoteDataSource remoteDataSource;

  FieldRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Field>>> getAvailableFields({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final fieldModels = await remoteDataSource.getAvailableFields(
        startTime: startTime,
        endTime: endTime,
      );

      return Right(fieldModels);
    } on ServerException {
      return const Left(
        ServerFailure('Fallo al obtener la lista de canchas disponibles.'),
      );
    }
  }

  // ... (implementación de reserveField)

  @override
  Future<Either<Failure, bool>> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    required double totalCost,
  }) async {
    try {
      final success = await remoteDataSource.reserveField(
        fieldId: fieldId,
        startTime: startTime,
        endTime: endTime,
        userId: userId,
        totalCost: totalCost,
      );
      return Right(success);
    } on ServerException {
      return const Left(
        ServerFailure('El servidor no pudo procesar la reserva de la cancha.'),
      );
    } on ForbiddenException {
      return const Left(
        PermissionFailure(
          'Acción prohibida. No tienes los permisos necesarios.',
        ),
      );
    }
  }
}
