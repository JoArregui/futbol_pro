import 'package:isar/isar.dart';

part 'message_isar.g.dart';

@collection
class MessageIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  @Index()
  late String roomId;

  late String senderId;
  late String senderName;
  late String text;
  late DateTime timestamp;
  late String status; // MessageStatus.name
  late String type; // MessageType.name
  String? replyToId;
  String? imageUrl;
}
