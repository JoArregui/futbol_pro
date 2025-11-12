import 'package:equatable/equatable.dart';


class Message extends Equatable {
  final String id;
  final String senderId; 
  final String senderName; 
  final String text; 
  final DateTime timestamp; 

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
