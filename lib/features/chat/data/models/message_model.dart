import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    required super.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      timestamp: (json['timestamp'] as num).toDouble() == 0.0
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(
              (json['timestamp'] as num).toInt()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
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
