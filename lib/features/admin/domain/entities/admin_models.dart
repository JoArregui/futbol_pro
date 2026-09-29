import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String role;
  final String nickname;
  final String name;

  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.nickname,
    required this.name,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: (json['id'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'player').toString(),
        nickname: (json['nickname'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );

  @override
  List<Object> get props => [id, email, role, nickname, name];
}

class AdminStats extends Equatable {
  final int users;
  final int matches;
  final int fields;
  final int bookings;
  final int chats;

  const AdminStats({
    required this.users,
    required this.matches,
    required this.fields,
    required this.bookings,
    required this.chats,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        users: (json['users'] as num?)?.toInt() ?? 0,
        matches: (json['matches'] as num?)?.toInt() ?? 0,
        fields: (json['fields'] as num?)?.toInt() ?? 0,
        bookings: (json['bookings'] as num?)?.toInt() ?? 0,
        chats: (json['chats'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object> get props => [users, matches, fields, bookings, chats];
}

class AdminMatch extends Equatable {
  final String id;
  final String fieldId;
  final String time;
  final String status;

  const AdminMatch({
    required this.id,
    required this.fieldId,
    required this.time,
    required this.status,
  });

  factory AdminMatch.fromJson(Map<String, dynamic> json) => AdminMatch(
        id: (json['id'] ?? '').toString(),
        fieldId: (json['fieldId'] ?? '').toString(),
        time: (json['time'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
      );

  @override
  List<Object> get props => [id, fieldId, time, status];
}
