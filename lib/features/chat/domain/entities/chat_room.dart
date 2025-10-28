import 'package:equatable/equatable.dart';
import 'message.dart'; // Importamos la entidad Message

// Enum para definir los tipos de sala de chat
enum ChatRoomType {
  general, // Chat General Comunitario
  league, // Chat de Liga
  match, // Chat de Partido Amistoso
  private, // Chat Privado (futura fase)
}

// Entidad que representa una sala o canal de chat.
class ChatRoom extends Equatable {
  final String id;
  final ChatRoomType type; // Tipo de chat (general, league, match, private)
  final String title; // Nombre visible de la sala (e.g., "Liga 1", "Partido vs Ciclones")
  final List<String> memberIds; // IDs de los usuarios autorizados
  final Message? lastMessage; // El último mensaje enviado (útil para vistas previas)
  final String? relatedEntityId; // ID de la entidad relacionada (Liga ID, Partido ID, o User ID para privado)

  const ChatRoom({
    required this.id,
    required this.type,
    required this.title,
    required this.memberIds,
    this.lastMessage,
    this.relatedEntityId,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        memberIds,
        lastMessage,
        relatedEntityId,
      ];
}
