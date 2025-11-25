import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../entities/message.dart';
import '../entities/chat_room.dart';

abstract class ChatRepository {
  // Antes era Stream, ahora es Future
  Future<Either<Failure, List<Message>>> getMessages(String roomId); 

  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });

  Future<Either<Failure, void>> markMessagesAsRead(String roomId, String userId);

  // Antes era Stream, ahora es Future
  Future<Either<Failure, List<ChatRoom>>> getChatRooms(String userId); 
}