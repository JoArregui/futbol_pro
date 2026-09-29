import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking.dart';
import '../repositories/field_repository.dart';

class GetMisReservas implements UseCase<List<BookingInfo>, NoParams> {
  final FieldRepository repository;

  GetMisReservas(this.repository);

  @override
  Future<Either<Failure, List<BookingInfo>>> call(NoParams params) async {
    return repository.misReservas();
  }
}
