import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;

  AdminBloc({required this.repository}) : super(AdminInitial()) {
    on<AdminLoadRequested>(_onLoad);
    on<AdminUsersSearchRequested>(_onSearchUsers);
    on<AdminUsersSelectionChanged>(_onSelection);
    on<AdminBulkRoleRequested>(_onBulkRole);
    on<AdminBulkDeleteRequested>(_onBulkDelete);
    on<AdminMatchesSelectionChanged>(_onMatchSelection);
    on<AdminBulkCancelMatchesRequested>(_onBulkCancel);
  }

  Future<void> _onLoad(AdminLoadRequested e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final stats = await repository.getStats();
    final users = await repository.getUsers();
    final matches = await repository.getMatches();
    stats.fold(
      (f) => emit(AdminError(f.errorMessage)),
      (s) => users.fold(
        (f) => emit(AdminError(f.errorMessage)),
        (u) => matches.fold(
          (f) => emit(AdminError(f.errorMessage)),
          (m) => emit(AdminLoaded(
              stats: s, users: u, matches: m, selectedUserIds: const {})),
        ),
      ),
    );
  }

  Future<void> _onSearchUsers(
      AdminUsersSearchRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(current.copyWith(searchingUsers: true));
    final res = await repository.getUsers(query: e.query);
    res.fold(
      (f) => emit(AdminError(f.errorMessage)),
      (u) => emit(current.copyWith(users: u, searchingUsers: false)),
    );
  }

  void _onSelection(
      AdminUsersSelectionChanged e, Emitter<AdminState> emit) {
    final current = state;
    if (current is! AdminLoaded) return;
    final sel = Set<String>.from(current.selectedUserIds);
    if (e.selected) {
      sel.add(e.userId);
    } else {
      sel.remove(e.userId);
    }
    emit(current.copyWith(selectedUserIds: sel));
  }

  Future<void> _onBulkRole(
      AdminBulkRoleRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded || current.selectedUserIds.isEmpty) return;
    emit(AdminActionRunning(message: 'Actualizando roles...', prev: current));
    final res = await repository.bulkRole(
        ids: current.selectedUserIds.toList(), role: e.role);
    await res.fold(
      (f) async => emit(AdminError(f.errorMessage)),
      (_) async {
        final users = await repository.getUsers();
        users.fold(
          (f) => emit(AdminError(f.errorMessage)),
          (u) => emit(current.copyWith(users: u, selectedUserIds: {})),
        );
      },
    );
  }

  Future<void> _onBulkDelete(
      AdminBulkDeleteRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded || current.selectedUserIds.isEmpty) return;
    emit(AdminActionRunning(message: 'Eliminando...', prev: current));
    final res = await repository.bulkDelete(
        ids: current.selectedUserIds.toList());
    await res.fold(
      (f) async => emit(AdminError(f.errorMessage)),
      (_) async {
        final users = await repository.getUsers();
        final stats = await repository.getStats();
        users.fold(
          (f) => emit(AdminError(f.errorMessage)),
          (u) => stats.fold(
            (f) => emit(AdminError(f.errorMessage)),
            (s) => emit(current.copyWith(
                users: u, stats: s, selectedUserIds: {})),
          ),
        );
      },
    );
  }

  void _onMatchSelection(
      AdminMatchesSelectionChanged e, Emitter<AdminState> emit) {
    final current = state;
    if (current is! AdminLoaded) return;
    final sel = Set<String>.from(current.selectedMatchIds);
    if (e.selected) {
      sel.add(e.matchId);
    } else {
      sel.remove(e.matchId);
    }
    emit(current.copyWith(selectedMatchIds: sel));
  }

  Future<void> _onBulkCancel(
      AdminBulkCancelMatchesRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded || current.selectedMatchIds.isEmpty) return;
    emit(AdminActionRunning(message: 'Cancelando partidos...', prev: current));
    final res = await repository.bulkCancelMatches(
        ids: current.selectedMatchIds.toList());
    await res.fold(
      (f) async => emit(AdminError(f.errorMessage)),
      (_) async {
        final matches = await repository.getMatches();
        matches.fold(
          (f) => emit(AdminError(f.errorMessage)),
          (m) => emit(
              current.copyWith(matches: m, selectedMatchIds: {})),
        );
      },
    );
  }
}
