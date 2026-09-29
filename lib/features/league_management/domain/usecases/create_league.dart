import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tournament.dart';
import '../repositories/league_repository.dart';

class CreateLeague implements UseCase<Tournament, CreateLeagueParams> {
  final LeagueRepository repository;

  CreateLeague(this.repository);

  @override
  Future<Either<Failure, Tournament>> call(CreateLeagueParams params) async {
    if (params.nombre.trim().isEmpty) {
      return const Left(ValidationFailure('El nombre es obligatorio.'));
    }
    return repository.createLeague(
      nombre: params.nombre.trim(),
      descripcion: params.descripcion,
      maxEquipos: params.maxEquipos,
    );
  }
}

class CreateLeagueParams extends Equatable {
  final String nombre;
  final String descripcion;
  final int maxEquipos;

  const CreateLeagueParams({
    required this.nombre,
    this.descripcion = '',
    this.maxEquipos = 12,
  });

  @override
  List<Object> get props => [nombre, descripcion, maxEquipos];
}
