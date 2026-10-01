import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/field_repository.dart';

class ConfirmPago implements UseCase<bool, ConfirmPagoParams> {
  final FieldRepository repository;

  ConfirmPago(this.repository);

  @override
  Future<Either<Failure, bool>> call(ConfirmPagoParams params) async {
    return repository.confirmPago(
      pagoId: params.pagoId,
      orderId: params.orderId,
    );
  }
}

class ConfirmPagoParams extends Equatable {
  final String pagoId;
  final String orderId;

  const ConfirmPagoParams({required this.pagoId, required this.orderId});

  @override
  List<Object> get props => [pagoId, orderId];
}
