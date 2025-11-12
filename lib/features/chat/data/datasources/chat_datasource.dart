import 'dart:async';
import 'package:futbol_pro/core/errors/exceptions.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/chat_room.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> getMessagesStream(String roomId);
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });
  Future<void> markMessagesAsRead(String roomId, String userId);
  Future<List<ChatRoom>> getChatRooms(String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Map<String, List<MessageModel>> _messagesDb = {
    'general_chat_id': [
      MessageModel(
        id: 'msg1',
        senderId: 'user-001',
        senderName: 'Juan Pro',
        text: '¡Bienvenidos al chat general de FutbolPro!',
        timestamp: DateTime.now(),
      ),
      MessageModel(
        id: 'msg2',
        senderId: 'user-002',
        senderName: 'Maria Goleadora',
        text: 'Hola a todos, ¿quién para un partido hoy?',
        timestamp: DateTime.now(),
      ),
    ],
  };

  final _messageStreamController =
      StreamController<List<MessageModel>>.broadcast();

  ChatRemoteDataSourceImpl() {
    _messageStreamController.add(_messagesDb['general_chat_id'] ?? []);
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    if (!_messagesDb.containsKey(roomId)) {
      _messagesDb[roomId] = [];
    }

    return _messageStreamController.stream.map((list) {
      return list
          .where((msg) => (_messagesDb[roomId] ?? []).contains(msg))
          .toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (text.trim().isEmpty) {
      throw const ServerException(message: 'El mensaje no puede estar vacío.');
    }

    final newMessage = MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    if (_messagesDb.containsKey(roomId)) {
      _messagesDb[roomId]!.add(newMessage);
    } else {
      _messagesDb[roomId] = [newMessage];
    }

    _messageStreamController.add(_messagesDb['general_chat_id']!);
  }

  @override
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    print('Simulación: Sala $roomId marcada como leída por $userId');
    return;
  }

  @override
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final rooms = [
      const ChatRoomModel(
        id: 'general_chat_id',
        type: ChatRoomType.general,
        title: 'Chat Global Comunitario',
        memberIds: ['user-001', 'user-002'],
      ),
      const ChatRoomModel(
        id: 'league_1_id',
        type: ChatRoomType.league,
        title: 'Liga Pro - 2025',
        memberIds: ['user-001'],
      ),
    ];

    return rooms.where((room) => room.memberIds.contains(userId)).toList();
  }
}
