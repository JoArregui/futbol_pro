import 'package:futbol_pro/core/db/isar_service.dart';
import 'package:futbol_pro/features/chat/domain/entities/chat_room.dart';
import 'package:futbol_pro/features/chat/domain/entities/message.dart';

abstract class ChatLocalDataSource {
  Future<void> cacheChatRooms(String ownerId, List<ChatRoom> rooms);
  Future<List<ChatRoom>> getCachedChatRooms(String ownerId);
  Future<void> cacheMessages(String roomId, List<Message> messages);
  Future<List<Message>> getCachedMessages(String roomId);
  Future<void> cacheMessage(String roomId, Message message);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final IsarService isar;
  ChatLocalDataSourceImpl(this.isar);

  @override
  Future<void> cacheChatRooms(String ownerId, List<ChatRoom> rooms) =>
      isar.saveChatRooms(ownerId, rooms);
  @override
  Future<List<ChatRoom>> getCachedChatRooms(String ownerId) =>
      isar.getChatRooms(ownerId);
  @override
  Future<void> cacheMessages(String roomId, List<Message> messages) =>
      isar.saveMessages(roomId, messages);
  @override
  Future<List<Message>> getCachedMessages(String roomId) =>
      isar.getMessages(roomId);
  @override
  Future<void> cacheMessage(String roomId, Message message) =>
      isar.saveMessage(roomId, message);
}
