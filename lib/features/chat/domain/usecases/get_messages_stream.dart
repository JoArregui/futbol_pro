/* Stream<List<Message>> getMessagesStream(String chatRoomId) {
  return FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc(chatRoomId)
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .limit(50)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList());
} */




import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/stream_usecase.dart'; 
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

// Asumimos que esta es la firma del Use Case que devuelve el Stream envuelto en Either
class GetMessagesStream implements StreamUseCase<List<Message>, MessagesStreamParams> {
  final ChatRepository repository;

  GetMessagesStream(this.repository);

  @override
  Stream<Either<Failure, List<Message>>> call(MessagesStreamParams params) {
    // Implementación del repositorio (que ya devuelve Stream<Either<...>>)
    return repository.getMessagesStream(params.roomId);
  }
}

class MessagesStreamParams extends Equatable {
  final String roomId;
  const MessagesStreamParams({required this.roomId});

  @override
  List<Object> get props => [roomId];
}