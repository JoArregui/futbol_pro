import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import 'package:futbol_pro/core/errors/exceptions.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<MessageModel>> getMessagesStream(String roomId);
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });
  Future<void> markMessagesAsRead(String roomId, String userId);
  // Se actualiza a Stream para mantener la coherencia con la arquitectura reactiva
  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId); 
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  // 🟢 CORRECCIÓN: El constructor requiere la instancia de Firestore
  ChatRemoteDataSourceImpl({required this.firestore});

  // 🟢 CORRECCIÓN: Implementación real de la escucha de mensajes con Firestore
  @override
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Los mensajes más nuevos primero (para la lista)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList();
      } catch (e) {
        // En caso de error de mapeo, lanzamos una excepción
        throw ServerException(message: 'Error al mapear mensajes: $e');
      }
    });
  }

  // 🟢 CORRECCIÓN: Implementación real del envío de mensajes
  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      throw const ServerException(message: 'El mensaje no puede estar vacío.');
    }

    final messageRef = firestore.collection('chat_rooms').doc(roomId).collection('messages').doc();
    final timestamp = DateTime.now();
    
    final newMessageData = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: timestamp,
    ).toJson();

    // 1. Añadir el mensaje a la subcolección
    await messageRef.set(newMessageData);

    // 2. 🟢 Opcional: Actualizar el campo lastMessage en el documento de la sala
    await firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': newMessageData,
      'lastActive': timestamp.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    // Implementación real (ejemplo simple: actualizar un campo de la sala)
    try {
      await firestore.collection('chat_rooms').doc(roomId).update({
        'readBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } on Exception catch (e) {
      throw ServerException(message: 'Error al marcar como leído: $e');
    }
  }

  // 🟢 CORRECCIÓN: Implementación real de la escucha de salas con Firestore
  @override
  Stream<List<ChatRoomModel>> getChatRoomsStream(String userId) {
    return firestore
        .collection('chat_rooms')
        .where('memberIds', arrayContains: userId) // Filtrar por participante
        .orderBy('lastActive', descending: true) // Ordenar por actividad reciente
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc))
            .toList();
      } catch (e) {
        // En caso de error de mapeo, lanzamos una excepción
        throw ServerException(message: 'Error al mapear salas: $e');
      }
    });
  }
}