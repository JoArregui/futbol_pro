import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class SearchUsers implements UseCase<List<Map<String, dynamic>>, SearchUsersParams> {
  final ChatRepository repository;
  SearchUsers(this.repository);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(SearchUsersParams params) => repository.searchUsers(query: params.query, excludeUid: params.excludeUid);
}

class SearchUsersParams extends Equatable {
  final String query;
  final String excludeUid;
  const SearchUsersParams({required this.query, required this.excludeUid});
  @override
  List<Object> get props => [query, excludeUid];
}
