import 'dart:async';
import 'package:futbol_pro/core/errors/exceptions.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/chat_room.dart';


// Definición de la interfaz (mantener en otro archivo si sigues DDD/Clean Architecture)
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

// Implementación Mock
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  // Simulación de una base de datos de mensajes en memoria
  final Map<String, List<MessageModel>> _messagesDb = {
    'general_chat_id': [
      // Se eliminó 'const' aquí y en msg2. 'DateTime.now()' no es constante.
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

  // StreamController para simular la actualización en tiempo real de los mensajes
  final _messageStreamController = StreamController<List<MessageModel>>.broadcast();

  ChatRemoteDataSourceImpl() {
    // Inicialización del stream con el chat general (solo para el mock)
    _messageStreamController.add(_messagesDb['general_chat_id'] ?? []);
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    // Simula conectar a una sala y empezar a escuchar
    if (!_messagesDb.containsKey(roomId)) {
      _messagesDb[roomId] = [];
    }
    
    // Devolvemos el stream, el repositorio luego lo envolverá en Either
    return _messageStreamController.stream.map((list) {
      // Filtra solo los mensajes para la sala solicitada (simulación de una consulta real)
      // Nota: Esta lógica de filtro puede ser ineficiente para un mock, 
      // pero mantiene la intención original.
      return list.where((msg) => (_messagesDb[roomId] ?? []).contains(msg)).toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simular latencia

    if (text.trim().isEmpty) {
      throw ServerException(message: 'El mensaje no puede estar vacío.');
    }

    final newMessage = MessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    // 1. Añadir a la "base de datos"
    if (_messagesDb.containsKey(roomId)) {
      _messagesDb[roomId]!.add(newMessage);
    } else {
      _messagesDb[roomId] = [newMessage];
    }
    
    // 2. Disparar la actualización en el stream para todos los oyentes
    // Nota: Aquí se dispara una actualización con el chat general. En un real, 
    // se notificaría al stream solo de los cambios relevantes a cada sala.
    _messageStreamController.add(_messagesDb['general_chat_id']!); 
  }

  @override
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // En un entorno real, aquí se actualizaría un campo 'readBy' en Firestore.
    print('Simulación: Sala $roomId marcada como leída por $userId');
    return;
  }

  @override
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Simulación de salas a las que pertenece el usuario
    final rooms = [
      // Se eliminó 'const' aquí y en league_1_id.
      const ChatRoomModel(
        id: 'general_chat_id',
        type: ChatRoomType.general,
        title: 'Chat Global Comunitario',
        memberIds: ['user-001', 'user-002'], // Todos
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