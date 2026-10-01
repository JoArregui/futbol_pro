import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_models.dart';

abstract class AdminRepository {
  Future<Either<Failure, AdminStats>> getStats();
  Future<Either<Failure, List<AdminUser>>> getUsers({String query});
  Future<Either<Failure, int>> bulkRole({
    required List<String> ids,
    required String role,
  });
  Future<Either<Failure, int>> bulkDelete({required List<String> ids});
  Future<Either<Failure, List<AdminMatch>>> getMatches();
  Future<Either<Failure, int>> bulkCancelMatches({required List<String> ids});

  // Gestión completa superadmin
  Future<Either<Failure, List<AdminTeam>>> getTeams();
  Future<Either<Failure, List<AdminPlayer>>> getPlayers({String query});
  Future<Either<Failure, List<AdminField>>> getFields();
  Future<Either<Failure, List<AdminReferee>>> getReferees();
  Future<Either<Failure, List<AdminLeague>>> getLeagues();
  Future<Either<Failure, List<AdminMatch>>> getFriendlies();
  Future<Either<Failure, List<AdminTournament>>> getTournaments();
  Future<Either<Failure, AdminFinance>> getFinance();
  Future<Either<Failure, bool>> createTeam({
    required String name,
    String league,
  });
  Future<Either<Failure, bool>> createLeague({required String name});
  Future<Either<Failure, bool>> toggleFieldStatus({
    required String id,
    required String status,
  });

  // CRUD completo
  Future<Either<Failure, bool>> updateTeam({
    required String id,
    required String name,
  });
  Future<Either<Failure, bool>> deleteTeam({required String id});
  Future<Either<Failure, List<AdminPlayer>>> getTeamPlayers(String teamId);
  Future<Either<Failure, bool>> addPlayerToTeam({
    required String teamId,
    required String playerId,
  });
  Future<Either<Failure, bool>> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  });
  Future<Either<Failure, bool>> createField({
    required String name,
    double price,
    int capacity,
  });
  Future<Either<Failure, bool>> deleteField({required String id});
  Future<Either<Failure, bool>> createReferee({
    required String name,
    double fee,
  });
  Future<Either<Failure, bool>> updateReferee({
    required String id,
    String? name,
    double? fee,
    String? status,
  });
  Future<Either<Failure, bool>> deleteReferee({required String id});
  Future<Either<Failure, List<AdminAudit>>> getAudit({int limit});
}
