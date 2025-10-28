import '../../domain/entities/message.dart';

// Modelo de datos para la entidad Message.
// Se usa para la serialización desde/hacia la fuente de datos (ej. Firestore).
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    required super.timestamp,
  });

  // Factory para crear un MessageModel desde un mapa (ej. documento Firestore o JSON).
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      // Se asume que el timestamp viene como un objeto que se puede convertir a DateTime.
      // Si usáramos Firestore, esto sería un Timestamp.
      timestamp: (json['timestamp'] as num).toDouble() == 0.0 
          ? DateTime.now() // Fallback si es 0
          : DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as num).toInt()),
    );
  }

  // Método para convertir el modelo a un mapa (ej. para guardar en Firestore).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      // Guardamos como milisegundos para simplificar el mock.
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Método para crear un modelo a partir de la entidad de dominio.
  factory MessageModel.fromEntity(Message entity) {
    return MessageModel(
      id: entity.id,
      senderId: entity.senderId,
      senderName: entity.senderName,
      text: entity.text,
      timestamp: entity.timestamp,
    );
  }
}