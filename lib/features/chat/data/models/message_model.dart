import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    required super.timestamp,
  });

  // 🟢 CORRECCIÓN: Mapeo desde DocumentSnapshot de Firestore
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      text: data['text'] as String,
      // Convertir Timestamp a DateTime
      timestamp: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final timestampData = json['timestamp'];
    DateTime timestamp;

    if (timestampData is int) {
      // Si el timestamp es un int (millisecondsSinceEpoch)
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    } else if (timestampData is double) {
      // Si el timestamp es un double (error en tu código anterior, ajustado a int)
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData.toInt());
    } else if (timestampData is Timestamp) {
      // Si el timestamp es un Timestamp de Firestore
      timestamp = timestampData.toDate();
    } else {
      timestamp = DateTime.now();
    }

    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      // 🟢 CORRECCIÓN: Guardar como millisecondsSinceEpoch (o usar FieldValue.serverTimestamp() en el envío)
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

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