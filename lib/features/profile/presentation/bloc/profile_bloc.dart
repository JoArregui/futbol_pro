import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
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

  /// Nombre real del usuario en sesión (para creación de perfil fallback,
  /// en lugar de placeholders quemados en la UI).
  String get currentUserName => authRepository.getCurrentUserName();

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.createProfile,
    required this.authRepository,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdated>(_onProfileUpdated);
  }

  bool _isNotFound(Object e) {
    if (e is NotFoundException) return true;
    final s = e.toString();
    // El repo envuelve: 'Fallo en el Repositorio al obtener perfil: ...'
    // + datasource 'Perfil de usuario no encontrado.'
    return s.contains('Perfil de usuario no encontrado') ||
        s.contains('NotFoundException');
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
      if (_isNotFound(e)) {
        try {
          final newProfile = await createProfile(
            uid: event.uid,
            email: event.email,
            nickname: event.nickname,
          );
          emit(ProfileLoaded(profile: newProfile));
          return;
        } catch (createError) {
          emit(
            ProfileError(
              'Error al crear y cargar el perfil: ${createError.toString()}',
            ),
          );
          return;
        }
      }

      emit(ProfileError('Error al cargar el perfil: ${e.toString()}'));
    }
  }

  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      emit(
        const ProfileError(
          'No se pudo actualizar: el perfil no estaba cargado.',
        ),
      );
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
        position: event.position,
        foot: event.foot,
        available: event.available,
      );

      final updatedProfile = await getProfile(event.uid);

      emit(ProfileUpdateSuccess(profile: updatedProfile));
    } catch (e) {
      // Un solo estado: mantiene perfil + muestra error (antes doble emit).
      emit(
        currentState.copyWith(
          isUpdating: false,
          error: 'Error al actualizar: ${e.toString()}',
        ),
      );
    }
  }
}
