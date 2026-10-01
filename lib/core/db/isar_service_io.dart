import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar/chat_room_isar.dart';
import 'isar/message_isar.dart';
import 'package:futbol_pro/features/chat/domain/entities/chat_room.dart';
import 'package:futbol_pro/features/chat/domain/entities/message.dart';
import 'package:futbol_pro/features/chat/data/models/message_model.dart';

class IsarService {
  late Isar isar;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final directory = (await getApplicationDocumentsDirectory()).path;
    isar = await Isar.open(
      [ChatRoomIsarSchema, MessageIsarSchema],
      directory: directory,
      name: 'futbol_pro',
    );
    _ready = true;
  }

  Future<void> saveChatRooms(String ownerId, List<ChatRoom> rooms) async {
    await isar.writeTxn(() async {
      for (final room in rooms) {
        final object = ChatRoomIsar()
          ..remoteId = room.id
          ..title = room.title
          ..type = room.type.name
          ..memberIds = room.memberIds
          ..relatedEntityId = room.relatedEntityId
          ..avatarUrl = room.avatarUrl
          ..unreadCount = room.unreadCount
          ..lastActive = room.lastActive
          ..isMuted = room.isMuted
          ..isPinned = room.isPinned
          ..ownerId = ownerId
          ..lastMessageJson = room.lastMessage == null
              ? null
              : jsonEncode(MessageModel.fromEntity(room.lastMessage!).toJson());
        await isar.chatRoomIsars.put(object);
      }
    });
  }

  Future<List<ChatRoom>> getChatRooms(String ownerId) async {
    final list = await isar.chatRoomIsars
        .filter()
        .ownerIdEqualTo(ownerId)
        .sortByLastActiveDesc()
        .findAll();
    return list.map((room) {
      Message? lastMessage;
      if (room.lastMessageJson != null) {
        try {
          lastMessage = MessageModel.fromJson(
            jsonDecode(room.lastMessageJson!),
          );
        } catch (_) {}
      }
      return ChatRoom(
        id: room.remoteId,
        title: room.title,
        type: ChatRoomType.values.firstWhere(
          (value) => value.name == room.type,
          orElse: () => ChatRoomType.private,
        ),
        memberIds: room.memberIds,
        lastMessage: lastMessage,
        relatedEntityId: room.relatedEntityId,
        avatarUrl: room.avatarUrl,
        unreadCount: room.unreadCount,
        lastActive: room.lastActive,
        isMuted: room.isMuted,
        isPinned: room.isPinned,
      );
    }).toList();
  }

  Future<void> saveMessages(String roomId, List<Message> messages) async {
    await isar.writeTxn(() async {
      for (final message in messages) {
        await isar.messageIsars.put(_toIsarMessage(roomId, message));
      }
    });
  }

  Future<List<Message>> getMessages(String roomId) async {
    final list = await isar.messageIsars
        .filter()
        .roomIdEqualTo(roomId)
        .sortByTimestampDesc()
        .limit(50)
        .findAll();
    return list.map(_fromIsarMessage).toList();
  }

  Future<void> saveMessage(String roomId, Message message) async {
    await isar.writeTxn(() async {
      await isar.messageIsars.put(_toIsarMessage(roomId, message));
    });
  }

  Future<void> clear() async {
    await isar.writeTxn(() async => isar.clear());
  }

  MessageIsar _toIsarMessage(String roomId, Message message) {
    return MessageIsar()
      ..remoteId = message.id
      ..roomId = roomId
      ..senderId = message.senderId
      ..senderName = message.senderName
      ..text = message.text
      ..timestamp = message.timestamp
      ..status = message.status.name
      ..type = message.type.name
      ..replyToId = message.replyToId
      ..imageUrl = message.imageUrl;
  }

  Message _fromIsarMessage(MessageIsar message) {
    return Message(
      id: message.remoteId,
      senderId: message.senderId,
      senderName: message.senderName,
      text: message.text,
      timestamp: message.timestamp,
      status: MessageStatus.values.firstWhere(
        (value) => value.name == message.status,
        orElse: () => MessageStatus.sent,
      ),
      type: MessageType.values.firstWhere(
        (value) => value.name == message.type,
        orElse: () => MessageType.text,
      ),
      replyToId: message.replyToId,
      imageUrl: message.imageUrl,
    );
  }
}
