import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final String nickname;
  final String profileImageUrl;
  final double rating;
  final String role;

  const Player({
    required this.id,
    required this.name,
    required this.nickname,
    required this.profileImageUrl,
    this.rating = 0.0,
    this.role = 'player',
  });

  bool get isSuperAdmin => role == 'superadmin';

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      profileImageUrl: (json['profileImageUrl'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      role: (json['role'] ?? 'player').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'role': role,
    };
  }

  @override
  List<Object> get props => [id, name, nickname, profileImageUrl, rating, role];
}
