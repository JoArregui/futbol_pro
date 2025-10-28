import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../entities/message.dart';
import '../entities/chat_room.dart';

abstract class ChatRepository {
  /// Devuelve un stream de mensajes para una sala de chat específica.
  Stream<Either<Failure, List<Message>>> getMessagesStream(String roomId);

  /// Envía un nuevo mensaje a una sala de chat.
  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });

  /// Marca todos los mensajes de una sala como leídos para un usuario.
  Future<Either<Failure, void>> markMessagesAsRead(String roomId, String userId);

  // 💡 CORREGIDO: La firma ahora coincide con el Use Case. El filtro por usuario
  // se hará internamente en la implementación (DataSource).
  Stream<Either<Failure, List<ChatRoom>>> getChatRooms(); 
}