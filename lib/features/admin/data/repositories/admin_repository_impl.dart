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
  Future<Either<Failure, int>> bulkRole(
      {required List<String> ids, required String role}) async {
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
  Future<Either<Failure, int>> bulkCancelMatches(
      {required List<String> ids}) async {
    try {
      return Right(await remote.bulkCancelMatches(ids: ids));
    } catch (e) {
      return _err(e);
    }
  }
}
