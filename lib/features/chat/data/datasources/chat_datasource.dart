import 'dart:async';
// ❌ ELIMINAMOS: import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:http/http.dart' as http; // 🟢 NUEVA DEPENDENCIA: HTTP
import 'dart:convert'; // Necesario para JSON

import 'package:futbol_pro/core/errors/exceptions.dart';
import 'package:futbol_pro/core/consts.dart';
import '../../domain/entities/chat_room.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

String get _kChatUrl => '${AppConsts.effectiveBaseUrl}/chats';


abstract class ChatRemoteDataSource {
  Future<List<MessageModel>> getMessages(String roomId);
  Future<void> sendMessage({required String roomId, required String senderId, required String senderName, required String text, String? imageUrl});
  Future<void> markMessagesAsRead(String roomId, String userId);
  Future<List<ChatRoomModel>> getChatRooms(String userId);
  Future<ChatRoomModel> createChat({required String title, required String type, required List<String> memberIds, String? relatedEntityId});
  Future<List<Map<String, dynamic>>> searchUsers({required String query, required String excludeUid});
}

// ----------------------------------------------------
// IMPLEMENTACIÓN CON API REST (MySQL)
// ----------------------------------------------------
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  // ❌ ELIMINADA la dependencia de Firestore
  final http.Client client;

  // 🟢 Constructor actualizado
  ChatRemoteDataSourceImpl({required this.client});

  
  /// Obtiene los mensajes de la sala por HTTP
  @override
  Future<List<MessageModel>> getMessages(String roomId) async {
    final url = Uri.parse('$_kChatUrl/$roomId/messages');

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Error al obtener mensajes: ${response.statusCode}');
      }
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }


  /// Envía un mensaje a la API REST para insertar en la BD
  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
  }) async {
    final url = Uri.parse('$_kChatUrl/$roomId/messages');

    try {
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'senderName': senderName,
          'text': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ServerException(message: 'Error al enviar mensaje: ${response.statusCode}');
      }
      
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión al enviar mensaje: $e');
    }
  }

  
  /// Marca los mensajes como leídos (asumiendo que la API actualizará la tabla chats)
  @override
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    final url = Uri.parse('$_kChatUrl/$roomId/read/$userId');

    try {
      // Usamos un PUT o POST para notificar al servidor
      final response = await client.put(url); 

      if (response.statusCode != 200) {
        throw ServerException(message: 'Error al marcar como leído: ${response.statusCode}');
      }
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }

  
  @override
  Future<ChatRoomModel> createChat({required String title, required String type, required List<String> memberIds, String? relatedEntityId}) async {
    final url = Uri.parse(_kChatUrl);
    final res = await client.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'title': title, 'type': type, 'memberIds': memberIds, if (relatedEntityId != null) 'relatedEntityId': relatedEntityId}));
    if (res.statusCode == 201 || res.statusCode == 200) {
      final j = jsonDecode(res.body);
      // Si solo devuelve id, construir room mínimo
      if (j['title'] == null) {
        return ChatRoomModel(id: j['id'].toString(), type: ChatRoomType.private, title: title, memberIds: memberIds);
      }
      return ChatRoomModel.fromJson(j);
    }
    throw ServerException(message: 'Error crear chat: ${res.statusCode}');
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers({required String query, required String excludeUid}) async {
    final url = Uri.parse('${AppConsts.effectiveBaseUrl}/users/search?q=${Uri.encodeComponent(query)}&excludeUid=$excludeUid');
    final res = await client.get(url);
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body);
      return list.cast<Map<String, dynamic>>();
    }
    throw ServerException(message: 'Error búsqueda: ${res.statusCode}');
  }

  /// Obtiene la lista de salas de chat del usuario
  @override
  Future<List<ChatRoomModel>> getChatRooms(String userId) async {
    final url = Uri.parse('$_kChatUrl/$userId/chats'); 

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ChatRoomModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Error al obtener salas: ${response.statusCode}');
      }
    } on Exception catch (e) {
      throw ServerException(message: 'Fallo de conexión: $e');
    }
  }
}
