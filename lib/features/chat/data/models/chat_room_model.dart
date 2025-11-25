import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import '../../domain/entities/chat_room.dart';
import 'message_model.dart';

class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.type,
    required super.title,
    required super.memberIds,
    super.lastMessage,
    super.relatedEntityId,
  });

  // 🟢 CORRECCIÓN: Mapeo desde DocumentSnapshot de Firestore
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String typeString = data['type'] as String;

    ChatRoomType type;
    try {
      type = ChatRoomType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
      );
    } catch (_) {
      type = ChatRoomType.general;
    }

    final lastMessageJson = data['lastMessage'] as Map<String, dynamic>?;
    final lastMessage =
        lastMessageJson != null ? MessageModel.fromJson(lastMessageJson) : null;

    return ChatRoomModel(
      id: doc.id,
      type: type,
      title: data['title'] as String,
      // Usar 'memberIds' (el campo de las reglas de seguridad)
      memberIds: List<String>.from(data['memberIds'] as List), 
      lastMessage: lastMessage,
      relatedEntityId: data['relatedEntityId'] as String?,
    );
  }

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final String typeString = json['type'] as String;

    ChatRoomType type;
    try {
      type = ChatRoomType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
      );
    } catch (_) {
      type = ChatRoomType.general;
    }

    final lastMessageJson = json['lastMessage'] as Map<String, dynamic>?;
    final lastMessage =
        lastMessageJson != null ? MessageModel.fromJson(lastMessageJson) : null;

    return ChatRoomModel(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      lastMessage: lastMessage,
      relatedEntityId: json['relatedEntityId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'memberIds': memberIds,
      'lastMessage': lastMessage != null
          ? MessageModel.fromEntity(lastMessage!).toJson()
          : null,
      'relatedEntityId': relatedEntityId,
    };
  }
}