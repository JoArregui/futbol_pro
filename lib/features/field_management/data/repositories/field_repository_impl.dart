import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/field.dart';
import '../../domain/repositories/field_repository.dart';
import '../datasources/field_remote_data_source.dart';

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
      return Right(fieldModels); // Devuelve List<Field> (ya que Model extiende Entity)
    } on ServerException {
      return Left(ServerFailure());
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
      return Left(ServerFailure());
    } on ForbiddenException { // Asumiendo que el usuario no tiene permisos/fondos
      return Left(CacheFailure()); // Usarías una Failure específica como NotEnoughFundsFailure
    }
  }
}