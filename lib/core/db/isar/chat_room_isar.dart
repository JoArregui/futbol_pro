import 'package:isar/isar.dart';

part 'chat_room_isar.g.dart';

@collection
class ChatRoomIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late String title;
  late String type;
  List<String> memberIds = [];
  String? lastMessageJson;
  String? relatedEntityId;
  String? avatarUrl;
  int unreadCount = 0;
  DateTime? lastActive;
  bool isMuted = false;
  bool isPinned = false;
  @Index()
  late String ownerId; // para filtrar por usuario local (multi-user en un móvil)
}
