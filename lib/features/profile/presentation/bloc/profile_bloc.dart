import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile.dart'; 
import '../../domain/usecases/update_profile.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final String currentUserId; 

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.currentUserId,
  }) : super(const ProfileInitial()) { 
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdated>(_onProfileUpdated);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await getProfile(event.uid); 
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      emit(ProfileError('Error al cargar el perfil: ${e.toString()}'));
    }
  }

  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(const ProfileError('No se pudo actualizar: el perfil no estaba cargado.'));
      return;
    }

    emit(currentState.copyWith(isUpdating: true)); 

    try {
      await updateProfile(
        uid: event.uid,
        nickname: event.nickname,
        name: event.name,
        bio: event.bio,
        avatarUrl: event.avatarUrl,
      );

      final updatedProfile = await getProfile(event.uid);
      
      emit(ProfileUpdateSuccess(profile: updatedProfile));
      
    } catch (e) {
      emit(ProfileError('Error al actualizar el perfil: ${e.toString()}'));
      emit(currentState.copyWith(isUpdating: false));
    }
  }
}