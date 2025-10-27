import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart'; 
import '../../../../core/errors/failures.dart';  
import '../../domain/entities/match.dart'; 
import '../../domain/repositories/match_repository.dart'; 
import '../datasources/match_remote_datasource.dart';
import '../models/match_model.dart'; 

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource remoteDataSource;
  // Puedes añadir otros Data Sources aquí si los necesitas (ej: localDataSource, networkChecker)

  MatchRepositoryImpl({required this.remoteDataSource});

  // ===============================================
  // MÉTODO AUXILIAR PARA MANEJO DE ERRORES CENTRALIZADO
  // ===============================================
  Either<Failure, T> _handleException<T>(dynamic exception) {
    if (exception is ConflictException) {
      // Usamos ValidationFailure ya que un conflicto es típicamente un error de lógica de negocio/validación
      // Nota: Si tus Failures tienen un constructor con 'message', úsalo aquí. 
      // Si no, adapta el constructor. Asumiendo que el constructor recibe solo el mensaje.
      return const Left(ValidationFailure('El partido ya está lleno o ya te has inscrito.'));
    } else if (exception is UnauthorizedException) {
      return const Left(AuthenticationFailure('No autorizado. Por favor, inicia sesión.'));
    } else if (exception is ForbiddenException) {
      return const Left(PermissionFailure('No tienes permiso para realizar esta acción.'));
    } else if (exception is NotFoundException) {
      return const Left(NotFoundFailure('El recurso solicitado no fue encontrado.'));
    } else if (exception is ServerException) {
      // Captura otros errores 4xx o 5xx genéricos
      return const Left(ServerFailure('Error en el servidor. Inténtalo de nuevo más tarde.'));
    } 
    // Captura cualquier excepción no mapeada (debe ser raro)
    else {
      // ✅ Solución: Usamos ServerFailure o, idealmente, una subclase UnknownFailure si existe.
      // Usamos ServerFailure como fallback general.
      return const Left(ServerFailure('Ocurrió un error inesperado.')); 
    }
  }

  // ===============================================
  // IMPLEMENTACIÓN DE MÉTODOS DEL REPOSITORIO
  // ===============================================
  
  @override
  Future<Either<Failure, Match>> joinMatch({
    required String matchId,
    required String playerId,
  }) async {
    try {
      final MatchModel matchModel = await remoteDataSource.addPlayerToMatch(
        matchId: matchId,
        playerId: playerId,
      );
      return Right(matchModel); // MatchModel es también la Entidad Match
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Either<Failure, Match>> scheduleFriendlyMatch({
    required DateTime time,
    required String fieldId,
  }) async {
    try {
      final MatchModel matchModel = await remoteDataSource.scheduleFriendlyMatch(
        time: time,
        fieldId: fieldId,
      );
      return Right(matchModel);
    } catch (e) {
      return _handleException(e);
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getUpcomingMatches() async {
    try {
      final List<MatchModel> matchModels = await remoteDataSource.getUpcomingMatches();
      // Retorna la lista de modelos, que son también entidades Match
      return Right(matchModels);
    } catch (e) {
      return _handleException(e);
    }
  }
}