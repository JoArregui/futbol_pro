import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    required super.timestamp,
    super.status = MessageStatus.sent,
    super.type = MessageType.text,
    super.replyToId,
    super.imageUrl,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      text: data['text'] as String,
      timestamp: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'];
    DateTime timestamp;
    if (ts is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is double) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    } else if (ts is String) {
      timestamp = DateTime.tryParse(ts) ?? DateTime.now();
    } else if (ts is Timestamp) {
      timestamp = ts.toDate();
    } else {
      timestamp = DateTime.now();
    }
    MessageStatus status = MessageStatus.sent;
    final s = json['status'] as String?;
    if (s != null)
      status = MessageStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => MessageStatus.sent,
      );

    return MessageModel(
      id: (json['id'] ?? json['id_mensaje'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['id_emisor_fk'] ?? '').toString(),
      senderName: (json['senderName'] ?? json['nombre_emisor'] ?? 'Usuario')
          .toString(),
      text: (json['text'] ?? json['texto'] ?? '').toString(),
      timestamp: timestamp,
      status: status,
      type: json['imageUrl'] != null ? MessageType.image : MessageType.text,
      imageUrl: json['imageUrl'] as String?,
      replyToId: json['replyToId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'status': status.name,
    'type': type.name,
    if (replyToId != null) 'replyToId': replyToId,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  factory MessageModel.fromEntity(Message entity) => MessageModel(
    id: entity.id,
    senderId: entity.senderId,
    senderName: entity.senderName,
    text: entity.text,
    timestamp: entity.timestamp,
    status: entity.status,
    type: entity.type,
    replyToId: entity.replyToId,
    imageUrl: entity.imageUrl,
  );
}
