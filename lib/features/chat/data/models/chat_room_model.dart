import '../../domain/entities/chat_room.dart';
import 'message_model.dart';

// Modelo de datos para la entidad ChatRoom.
class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.type,
    required super.title,
    required super.memberIds,
    super.lastMessage,
    super.relatedEntityId,
  });

  // Factory para crear un ChatRoomModel desde un mapa.
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final String typeString = json['type'] as String;
    
    // Mapeo del String a ChatRoomType Enum
    ChatRoomType type;
    try {
      type = ChatRoomType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
      );
    } catch (_) {
      type = ChatRoomType.general; // Fallback
    }

    // Mapeo del último mensaje
    final lastMessageJson = json['lastMessage'] as Map<String, dynamic>?;
    final lastMessage = lastMessageJson != null
        ? MessageModel.fromJson(lastMessageJson)
        : null;

    return ChatRoomModel(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      lastMessage: lastMessage,
      relatedEntityId: json['relatedEntityId'] as String?,
    );
  }

  // Método para convertir el modelo a un mapa.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last, // Almacenamos solo el nombre del enum
      'title': title,
      'memberIds': memberIds,
      'lastMessage': lastMessage != null 
          ? MessageModel.fromEntity(lastMessage!).toJson() 
          : null,
      'relatedEntityId': relatedEntityId,
    };
  }
}
