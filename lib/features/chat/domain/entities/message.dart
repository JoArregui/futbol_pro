import 'package:equatable/equatable.dart';

// Entidad que representa un mensaje individual dentro de una sala de chat.
class Message extends Equatable {
  final String id;
  final String senderId; // ID del usuario que envía el mensaje
  final String senderName; // Nombre o nickname del remitente
  final String text; // Contenido del mensaje
  final DateTime timestamp; // Momento en que se envió el mensaje

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object> get props => [id, senderId, senderName, text, timestamp];
}
