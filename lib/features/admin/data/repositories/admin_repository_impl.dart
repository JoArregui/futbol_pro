import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remote;
  AdminRepositoryImpl({required this.remote});

  Either<Failure, T> _err<T>(Object e) {
    if (e is ServerException) return Left(ServerFailure(e.message));
    return Left(ServerFailure('Error admin: $e'));
  }

  @override
  Future<Either<Failure, AdminStats>> getStats() async {
    try {
      return Right(await remote.getStats());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminUser>>> getUsers({String query = ''}) async {
    try {
      return Right(await remote.getUsers(query: query));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, int>> bulkRole({
    required List<String> ids,
    required String role,
  }) async {
    try {
      return Right(await remote.bulkRole(ids: ids, role: role));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, int>> bulkDelete({required List<String> ids}) async {
    try {
      return Right(await remote.bulkDelete(ids: ids));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminMatch>>> getMatches() async {
    try {
      return Right(await remote.getMatches());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, int>> bulkCancelMatches({
    required List<String> ids,
  }) async {
    try {
      return Right(await remote.bulkCancelMatches(ids: ids));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminTeam>>> getTeams() async {
    try {
      return Right(await remote.getTeams());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminPlayer>>> getPlayers({
    String query = '',
  }) async {
    try {
      return Right(await remote.getPlayers(query: query));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminField>>> getFields() async {
    try {
      return Right(await remote.getFields());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminReferee>>> getReferees() async {
    try {
      return Right(await remote.getReferees());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminLeague>>> getLeagues() async {
    try {
      return Right(await remote.getLeagues());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminMatch>>> getFriendlies() async {
    try {
      return Right(await remote.getFriendlies());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminTournament>>> getTournaments() async {
    try {
      return Right(await remote.getTournaments());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, AdminFinance>> getFinance() async {
    try {
      return Right(await remote.getFinance());
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> createTeam({
    required String name,
    String league = '',
  }) async {
    try {
      return Right(await remote.createTeam(name: name, league: league));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> createLeague({required String name}) async {
    try {
      return Right(await remote.createLeague(name: name));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> toggleFieldStatus({
    required String id,
    required String status,
  }) async {
    try {
      return Right(await remote.toggleFieldStatus(id: id, status: status));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateTeam({
    required String id,
    required String name,
  }) async {
    try {
      return Right(await remote.updateTeam(id: id, name: name));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTeam({required String id}) async {
    try {
      return Right(await remote.deleteTeam(id: id));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminPlayer>>> getTeamPlayers(
    String teamId,
  ) async {
    try {
      return Right(await remote.getTeamPlayers(teamId));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> addPlayerToTeam({
    required String teamId,
    required String playerId,
  }) async {
    try {
      return Right(
        await remote.addPlayerToTeam(teamId: teamId, playerId: playerId),
      );
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  }) async {
    try {
      return Right(
        await remote.removePlayerFromTeam(teamId: teamId, playerId: playerId),
      );
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> createField({
    required String name,
    double price = 50,
    int capacity = 14,
  }) async {
    try {
      return Right(
        await remote.createField(name: name, price: price, capacity: capacity),
      );
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> deleteField({required String id}) async {
    try {
      return Right(await remote.deleteField(id: id));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> createReferee({
    required String name,
    double fee = 20,
  }) async {
    try {
      return Right(await remote.createReferee(name: name, fee: fee));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> updateReferee({
    required String id,
    String? name,
    double? fee,
    String? status,
  }) async {
    try {
      return Right(
        await remote.updateReferee(
          id: id,
          name: name,
          fee: fee,
          status: status,
        ),
      );
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, bool>> deleteReferee({required String id}) async {
    try {
      return Right(await remote.deleteReferee(id: id));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, List<AdminAudit>>> getAudit({int limit = 30}) async {
    try {
      return Right(await remote.getAudit(limit: limit));
    } catch (e) {
      return _err(e);
    }
  }

  @override
  Future<Either<Failure, AdminPlayer>> createManualPlayer({
    required String apodo,
    String? nombre,
    String? email,
  }) async {
    try {
      return Right(await remote.createManualPlayer(
        apodo: apodo,
        nombre: nombre,
        email: email,
      ));
    } catch (e) {
      return _err(e);
    }
  }
}
