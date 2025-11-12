import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../entities/message.dart';
import '../entities/chat_room.dart';

abstract class ChatRepository {
  Stream<Either<Failure, List<Message>>> getMessagesStream(String roomId);

  /// Envía un nuevo mensaje a una sala de chat.
  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });

  /// Marca todos los mensajes de una sala como leídos para un usuario.
  Future<Either<Failure, void>> markMessagesAsRead(
      String roomId, String userId);

  Stream<Either<Failure, List<ChatRoom>>> getChatRooms();
}
