import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/create_profile.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final CreateProfile createProfile;
  final AuthRepository authRepository;

  String get currentUserId => authRepository.getCurrentUserId();

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.createProfile,
    required this.authRepository,
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
      // 🚀 Lógica de CATCH-AND-CREATE: Si el perfil no existe, créalo.
      if (e.toString().contains('Usuario no encontrado')) {
        try {
          // 1. Crear el perfil inicial
          final newProfile = await createProfile(
            uid: event.uid,
            email: event.email,
            nickname: event.nickname,
          );
          // 2. Emitir el perfil recién creado
          emit(ProfileLoaded(profile: newProfile));
          return;
        } catch (createError) {
          emit(ProfileError('Error al crear y cargar el perfil: ${createError.toString()}'));
          return;
        }
      }
      
      // Error general
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

      // 🚀 Cargar el perfil nuevamente para obtener la versión actualizada de Firestore
      final updatedProfile = await getProfile(event.uid);
      
      emit(ProfileUpdateSuccess(profile: updatedProfile));
      
    } catch (e) {
      emit(ProfileError('Error al actualizar el perfil: ${e.toString()}'));
      // Volver al estado cargado anterior si la actualización falla.
      emit(currentState.copyWith(isUpdating: false));
    }
  }
}