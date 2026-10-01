part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String uid;

  // 🚀 Añadimos email y nickname, que son obligatorios para la creación inicial
  final String email;
  final String nickname;

  const ProfileLoadRequested(this.uid,
      {required this.email, required this.nickname});

  @override
  List<Object> get props => [uid, email, nickname];
}

class ProfileUpdated extends ProfileEvent {
  final String uid;
  final String? nickname;
  final String? name;
  final String? bio;
  final String? avatarUrl;
  final String? position;
  final String? foot;
  final bool? available;

  const ProfileUpdated({
    required this.uid,
    this.nickname,
    this.name,
    this.bio,
    this.avatarUrl,
    this.position,
    this.foot,
    this.available,
  });

  @override
  List<Object?> get props =>
      [uid, nickname, name, bio, avatarUrl, position, foot, available];
}
