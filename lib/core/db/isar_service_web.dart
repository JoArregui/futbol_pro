import 'package:futbol_pro/features/chat/domain/entities/chat_room.dart';
import 'package:futbol_pro/features/chat/domain/entities/message.dart';

class IsarService {
  final Map<String, ChatRoom> _chatRooms = {};
  final Map<String, Message> _messages = {};

  Future<void> init() async {}

  Future<void> saveChatRooms(String ownerId, List<ChatRoom> rooms) async {
    _chatRooms.removeWhere((key, _) => key.startsWith('$ownerId:'));
    for (final room in rooms) {
      _chatRooms['$ownerId:${room.id}'] = room;
    }
  }

  Future<List<ChatRoom>> getChatRooms(String ownerId) async {
    return _chatRooms.entries
        .where((entry) => entry.key.startsWith('$ownerId:'))
        .map((entry) => entry.value)
        .toList();
  }

  Future<void> saveMessages(String roomId, List<Message> messages) async {
    for (final message in messages) {
      _messages['$roomId:${message.id}'] = message;
    }
  }

  Future<List<Message>> getMessages(String roomId) async {
    return _messages.entries
        .where((entry) => entry.key.startsWith('$roomId:'))
        .map((entry) => entry.value)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveMessage(String roomId, Message message) async {
    _messages['$roomId:${message.id}'] = message;
  }

  Future<void> clear() async {
    _chatRooms.clear();
    _messages.clear();
  }
}
