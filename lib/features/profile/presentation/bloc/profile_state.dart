part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
  }
class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final bool isUpdating;

  const ProfileLoaded({
    required this.profile,
    this.isUpdating = false,
  });
  
  ProfileLoaded copyWith({
    UserProfile? profile,
    bool? isUpdating,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object> get props => [profile, isUpdating];
}

class ProfileUpdateSuccess extends ProfileLoaded {
  const ProfileUpdateSuccess({required super.profile}) : super(isUpdating: false);
}