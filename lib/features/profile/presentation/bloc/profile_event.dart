part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  // 🟢 CORREGIDO: Usamos List<Object?> en la clase base para que coincida con la subclase
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String uid;

  const ProfileLoadRequested(this.uid);

  @override
  List<Object> get props => [uid];
}

class ProfileUpdated extends ProfileEvent {
  final String uid;
  final String? nickname;
  final String? name;
  final String? bio;
  final String? avatarUrl;

  const ProfileUpdated({
    required this.uid,
    this.nickname,
    this.name,
    this.bio,
    this.avatarUrl,
  });

  @override
  // Esto ahora es válido porque la base ProfileEvent.props permite List<Object?>
  List<Object?> get props => [uid, nickname, name, bio, avatarUrl]; 
}