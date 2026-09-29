import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_models.dart';

abstract class AdminRepository {
  Future<Either<Failure, AdminStats>> getStats();
  Future<Either<Failure, List<AdminUser>>> getUsers({String query});
  Future<Either<Failure, int>> bulkRole(
      {required List<String> ids, required String role});
  Future<Either<Failure, int>> bulkDelete({required List<String> ids});
  Future<Either<Failure, List<AdminMatch>>> getMatches();
  Future<Either<Failure, int>> bulkCancelMatches({required List<String> ids});
}
