import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.email,
    required super.nickname,
    super.name,
    super.avatarUrl,
    super.bio,
    required super.gamesPlayed,
    required super.wins,
    required super.rating,
    required super.createdAt,
  });

  factory UserProfileModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final timestamp = data['createdAt'] as Timestamp;

    return UserProfileModel(
      uid: doc.id,
      email: data['email'] as String,
      nickname: data['nickname'] as String,
      name: data['name'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      gamesPlayed: (data['gamesPlayed'] as num).toInt(),
      wins: (data['wins'] as num).toInt(),
      rating: (data['rating'] as num).toDouble(),
      createdAt: timestamp.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nickname': nickname,
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
