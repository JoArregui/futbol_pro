import 'package:equatable/equatable.dart';
import 'message.dart'; 


enum ChatRoomType {
  general,
  league, 
  match, 
  private,
}


class ChatRoom extends Equatable {
  final String id;
  final ChatRoomType type;
  final String title; 
  final List<String> memberIds; 
  final Message? lastMessage; 
  final String? relatedEntityId; 

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
