import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/stream_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

class GetChatRoomsStream implements StreamUseCase<List<ChatRoom>, NoParams> {
  final ChatRepository repository;

  GetChatRoomsStream(this.repository);

  @override
  Stream<Either<Failure, List<ChatRoom>>> call(NoParams params) {
    return repository.getChatRooms();
  }
}
