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
  final String? error;

  const ProfileLoaded({
    required this.profile,
    this.isUpdating = false,
    this.error,
  });

  ProfileLoaded copyWith({
    UserProfile? profile,
    bool? isUpdating,
    String? error,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
    );
  }

  @override
  List<Object> get props => [profile, isUpdating, error ?? ''];
}

class ProfileUpdateSuccess extends ProfileLoaded {
  final DateTime updatedAt;
  ProfileUpdateSuccess({required super.profile})
    : updatedAt = DateTime.now(),
      super(isUpdating: false);

  @override
  List<Object> get props => [profile, isUpdating, error ?? '', updatedAt];
}
