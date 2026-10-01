import 'package:equatable/equatable.dart';

enum MessageStatus { sending, sent, delivered, read, failed }
enum MessageType { text, image, system }

class Message extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  final String? replyToId;
  final String? imageUrl;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
    this.replyToId,
    this.imageUrl,
  });

  Message copyWith({
    String? id,
    MessageStatus? status,
    String? text,
  }) =>
      Message(
        id: id ?? this.id,
        senderId: senderId,
        senderName: senderName,
        text: text ?? this.text,
        timestamp: timestamp,
        status: status ?? this.status,
        type: type,
        replyToId: replyToId,
        imageUrl: imageUrl,
      );

  @override
  List<Object?> get props => [id, senderId, senderName, text, timestamp, status, type, replyToId, imageUrl];
}
