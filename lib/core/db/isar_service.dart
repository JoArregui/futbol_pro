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
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ChatRoomIsarSchema, MessageIsarSchema],
      directory: dir.path,
      name: 'futbol_pro',
    );
    _ready = true;
  }

  // === ChatRoom ===
  Future<void> saveChatRooms(String ownerId, List<ChatRoom> rooms) async {
    await isar.writeTxn(() async {
      for (final r in rooms) {
        final isarObj = ChatRoomIsar()
          ..remoteId = r.id
          ..title = r.title
          ..type = r.type.name
          ..memberIds = r.memberIds
          ..relatedEntityId = r.relatedEntityId
          ..avatarUrl = r.avatarUrl
          ..unreadCount = r.unreadCount
          ..lastActive = r.lastActive
          ..isMuted = r.isMuted
          ..isPinned = r.isPinned
          ..ownerId = ownerId
          ..lastMessageJson = r.lastMessage != null ? jsonEncode(MessageModel.fromEntity(r.lastMessage!).toJson()) : null;
        await isar.chatRoomIsars.put(isarObj);
      }
    });
  }

  Future<List<ChatRoom>> getChatRooms(String ownerId) async {
    final list = await isar.chatRoomIsars.filter().ownerIdEqualTo(ownerId).sortByLastActiveDesc().findAll();
    return list.map((e) {
      Message? last;
      if (e.lastMessageJson != null) {
        try { last = MessageModel.fromJson(jsonDecode(e.lastMessageJson!)); } catch (_) {}
      }
      return ChatRoom(
        id: e.remoteId,
        title: e.title,
        type: ChatRoomType.values.firstWhere((v) => v.name == e.type, orElse: () => ChatRoomType.private),
        memberIds: e.memberIds,
        lastMessage: last,
        relatedEntityId: e.relatedEntityId,
        avatarUrl: e.avatarUrl,
        unreadCount: e.unreadCount,
        lastActive: e.lastActive,
        isMuted: e.isMuted,
        isPinned: e.isPinned,
      );
    }).toList();
  }

  // === Message ===
  Future<void> saveMessages(String roomId, List<Message> messages) async {
    await isar.writeTxn(() async {
      for (final m in messages) {
        final obj = MessageIsar()
          ..remoteId = m.id
          ..roomId = roomId
          ..senderId = m.senderId
          ..senderName = m.senderName
          ..text = m.text
          ..timestamp = m.timestamp
          ..status = m.status.name
          ..type = m.type.name
          ..replyToId = m.replyToId
          ..imageUrl = m.imageUrl;
        await isar.messageIsars.put(obj);
      }
    });
  }

  Future<List<Message>> getMessages(String roomId) async {
    final list = await isar.messageIsars.filter().roomIdEqualTo(roomId).sortByTimestampDesc().limit(50).findAll();
    return list.map((e) => Message(
          id: e.remoteId,
          senderId: e.senderId,
          senderName: e.senderName,
          text: e.text,
          timestamp: e.timestamp,
          status: MessageStatus.values.firstWhere((v) => v.name == e.status, orElse: () => MessageStatus.sent),
          type: MessageType.values.firstWhere((v) => v.name == e.type, orElse: () => MessageType.text),
          replyToId: e.replyToId,
          imageUrl: e.imageUrl,
        )).toList();
  }

  Future<void> saveMessage(String roomId, Message m) async {
    await isar.writeTxn(() async {
      final obj = MessageIsar()
        ..remoteId = m.id
        ..roomId = roomId
        ..senderId = m.senderId
        ..senderName = m.senderName
        ..text = m.text
        ..timestamp = m.timestamp
        ..status = m.status.name
        ..type = m.type.name
        ..replyToId = m.replyToId
        ..imageUrl = m.imageUrl;
      await isar.messageIsars.put(obj);
    });
  }

  Future<void> clear() async => isar.writeTxn(() async => isar.clear());
}
