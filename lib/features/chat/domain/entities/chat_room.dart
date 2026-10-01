import 'package:equatable/equatable.dart';
import 'message.dart';

enum ChatRoomType { general, league, match, private }

class ChatRoom extends Equatable {
  final String id;
  final ChatRoomType type;
  final String title;
  final List<String> memberIds;
  final Message? lastMessage;
  final String? relatedEntityId;
  final String? avatarUrl;
  final int unreadCount;
  final DateTime? lastActive;
  final bool isMuted;
  final bool isPinned;

  const ChatRoom({
    required this.id,
    required this.type,
    required this.title,
    required this.memberIds,
    this.lastMessage,
    this.relatedEntityId,
    this.avatarUrl,
    this.unreadCount = 0,
    this.lastActive,
    this.isMuted = false,
    this.isPinned = false,
  });

  bool get isGroup =>
      memberIds.length > 2 ||
      type == ChatRoomType.general ||
      type == ChatRoomType.league ||
      type == ChatRoomType.match;

  ChatRoom copyWith({
    int? unreadCount,
    Message? lastMessage,
    DateTime? lastActive,
  }) => ChatRoom(
    id: id,
    type: type,
    title: title,
    memberIds: memberIds,
    lastMessage: lastMessage ?? this.lastMessage,
    relatedEntityId: relatedEntityId,
    avatarUrl: avatarUrl,
    unreadCount: unreadCount ?? this.unreadCount,
    lastActive: lastActive ?? this.lastActive,
    isMuted: isMuted,
    isPinned: isPinned,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    memberIds,
    lastMessage,
    relatedEntityId,
    avatarUrl,
    unreadCount,
    lastActive,
    isMuted,
    isPinned,
  ];
}
