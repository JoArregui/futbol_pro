import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../entities/message.dart';
import '../entities/chat_room.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<Message>>> getMessages(String roomId);
  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
    String? clientId,
  });
  Future<Either<Failure, void>> markMessagesAsRead(
    String roomId,
    String userId,
  );
  Future<Either<Failure, List<ChatRoom>>> getChatRooms(String userId);
  Future<Either<Failure, ChatRoom>> createChat({
    required String title,
    required String type,
    required List<String> memberIds,
    String? relatedEntityId,
  });
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsers({
    required String query,
    required String excludeUid,
  });
}
