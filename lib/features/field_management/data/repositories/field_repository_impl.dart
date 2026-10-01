import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/booking.dart';
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
  Future<Either<Failure, BookingInfo>> reserveField({
    required String fieldId,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    String? paymentMethod,
  }) async {
    try {
      final booking = await remoteDataSource.reserveField(
        fieldId: fieldId,
        startTime: startTime,
        endTime: endTime,
        userId: userId,
        paymentMethod: paymentMethod,
      );
      return Right(booking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ForbiddenException {
      return const Left(
        PermissionFailure(
          'Acción prohibida. No tienes los permisos necesarios.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> confirmPago(
      {required String pagoId, required String orderId}) async {
    try {
      final ok =
          await remoteDataSource.confirmPago(pagoId: pagoId, orderId: orderId);
      return Right(ok);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<BookingInfo>>> misReservas() async {
    try {
      final list = await remoteDataSource.misReservas();
      return Right(list);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
