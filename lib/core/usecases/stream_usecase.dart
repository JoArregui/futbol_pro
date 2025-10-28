import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

// T = Tipo de dato que emite el Stream (List<Message>)
// P = Tipo de parámetros (GetMessagesParams)
abstract class StreamUseCase<T, P extends Equatable> {
  // El método 'call' ahora devuelve el Stream directamente, 
  // manejando los posibles errores con Either<Failure, T> en cada emisión.
  Stream<Either<Failure, T>> call(P params);
}