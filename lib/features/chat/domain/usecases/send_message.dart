import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/chat_repository.dart';

class SendMessage implements UseCase<void, SendParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(SendParams params) async {
    if (params.content.trim().isEmpty) {
      return const Left(ValidationFailure('El mensaje no puede estar vacío.'));
    }

    return await repository.sendMessage(
      roomId: params.roomId,
      senderId: params.senderId,
      senderName: params.senderName,
      text: params.content,
    );
  }
}

class SendParams extends Equatable {
  final String roomId;
  final String senderId;
  final String content;

  final String senderName;

  const SendParams({
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.senderName,
  });

  @override
  List<Object> get props => [roomId, senderId, content, senderName];
}
