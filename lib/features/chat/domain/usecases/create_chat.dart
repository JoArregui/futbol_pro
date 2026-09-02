import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'package:futbol_pro/core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

class CreateChat implements UseCase<ChatRoom, CreateChatParams> {
  final ChatRepository repository;
  CreateChat(this.repository);
  @override
  Future<Either<Failure, ChatRoom>> call(CreateChatParams params) => repository.createChat(title: params.title, type: params.type, memberIds: params.memberIds, relatedEntityId: params.relatedEntityId);
}

class CreateChatParams extends Equatable {
  final String title;
  final String type;
  final List<String> memberIds;
  final String? relatedEntityId;
  const CreateChatParams({required this.title, required this.type, required this.memberIds, this.relatedEntityId});
  @override
  List<Object?> get props => [title, type, memberIds, relatedEntityId];
}
