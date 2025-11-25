import 'dart:async';
// ❌ ELIMINAMOS: import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:http/http.dart' as http; // 🟢 NUEVA DEPENDENCIA: HTTP
import 'dart:convert'; // Necesario para JSON

import 'package:futbol_pro/core/errors/exceptions.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

// URL base de tu API REST
const String _kBaseUrl = 'http://10.0.2.2:3000/api/v1'; 
const String _kChatUrl = '$_kBaseUrl/chats';


abstract class ChatRemoteDataSource {
  // 🔄 CAMBIO: De Stream a Future para API REST
  Future<List<MessageModel>> getMessages(String roomId);
  
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });
  
  Future<void> markMessagesAsRead(String roomId, String userId);
  
  // 🔄 CAMBIO: De Stream a Future para API REST
  Future<List<ChatRoomModel>> getChatRooms(String userId); 
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

  
  /// Obtiene la lista de salas de chat del usuario
  @override
  Future<List<ChatRoomModel>> getChatRooms(String userId) async {
    final url = Uri.parse('$_kBaseUrl/users/$userId/chats'); 

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