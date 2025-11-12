import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/stream_usecase.dart'; 
import '../entities/message.dart';
import '../repositories/chat_repository.dart';


class GetMessagesStream implements StreamUseCase<List<Message>, MessagesStreamParams> {
  final ChatRepository repository;

  GetMessagesStream(this.repository);

  @override
  Stream<Either<Failure, List<Message>>> call(MessagesStreamParams params) {

    return repository.getMessagesStream(params.roomId);
  }
}

class MessagesStreamParams extends Equatable {
  final String roomId;
  const MessagesStreamParams({required this.roomId});

  @override
  List<Object> get props => [roomId];
}