// lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

// T es el tipo de dato que devuelve el Use Case (ej. Player)
// P es el tipo de dato que acepta como Parámetros (ej. LoginParams)
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

// Clase para Use Cases que NO necesitan parámetros
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
