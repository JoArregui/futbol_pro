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
    on<AdminCreateTeamRequested>(_onCreateTeam);
    on<AdminCreateLeagueRequested>(_onCreateLeague);
    on<AdminToggleFieldRequested>(_onToggleField);
    on<AdminUpdateTeamRequested>(_onUpdateTeam);
    on<AdminDeleteTeamRequested>(_onDeleteTeam);
    on<AdminAddPlayerToTeamRequested>(_onAddPlayerToTeam);
    on<AdminRemovePlayerFromTeamRequested>(_onRemovePlayerFromTeam);
    on<AdminCreateFieldRequested>(_onCreateField);
    on<AdminDeleteFieldRequested>(_onDeleteField);
    on<AdminCreateRefereeRequested>(_onCreateReferee);
    on<AdminToggleRefereeRequested>(_onToggleReferee);
    on<AdminDeleteRefereeRequested>(_onDeleteReferee);
  }

  Future<void> _onLoad(AdminLoadRequested e, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    // Paralelo real: 3 críticos + 8 extendidos. friendlies se deriva de
    // matches (el datasource lo refetcheaba: doble GET + race).
    final results = await Future.wait([
      repository.getStats(),
      repository.getUsers(),
      repository.getMatches(),
      repository.getTeams(),
      repository.getPlayers(),
      repository.getFields(),
      repository.getReferees(),
      repository.getLeagues(),
      repository.getTournaments(),
      repository.getFinance(),
      repository.getAudit(limit: 20),
    ]);
    final stats = results[0] as dynamic;
    final users = results[1] as dynamic;
    final matches = results[2] as dynamic;
    final teams = results[3] as dynamic;
    final players = results[4] as dynamic;
    final fields = results[5] as dynamic;
    final referees = results[6] as dynamic;
    final leagues = results[7] as dynamic;
    final tournaments = results[8] as dynamic;
    final finance = results[9] as dynamic;
    final audit = results[10] as dynamic;

    if (stats.isLeft() || users.isLeft() || matches.isLeft()) {
      final f = stats.fold((l) => l, (_) => null) ??
          users.fold((l) => l, (_) => null) ??
          matches.fold((l) => l, (_) => null);
      emit(AdminError((f as Failure).errorMessage));
      return;
    }

    emit(AdminLoaded(
      stats: stats.getOrElse(() => const AdminStats(
          users: 0,
          matches: 0,
          fields: 0,
          bookings: 0,
          chats: 0,
          teams: 0,
          leagues: 0,
          referees: 0,
          revenue: 0)),
      users: users.getOrElse(() => []),
      matches: matches.getOrElse(() => []),
      teams: teams.getOrElse(() => []),
      players: players.getOrElse(() => []),
      fields: fields.getOrElse(() => []),
      referees: referees.getOrElse(() => []),
      leagues: leagues.getOrElse(() => []),
      friendlies: matches.getOrElse(() => <AdminMatch>[]).where((m) => m.type.toUpperCase() == 'AMISTOSO').toList(),
      tournaments: tournaments.getOrElse(() => []),
      finance: finance.getOrElse(() => AdminFinance.empty()),
      audit: audit.getOrElse(() => []),
    ));
  }

  Future<void> _onSearchUsers(
      AdminUsersSearchRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(current.copyWith(searchingUsers: true));
    final res = await repository.getUsers(query: e.query);
    final resPlayers = await repository.getPlayers(query: e.query);
    res.fold(
      (f) => emit(adminErr(f.errorMessage, current)),
      (u) => emit(current.copyWith(
        users: u,
        players: resPlayers.getOrElse(() => current.players),
        searchingUsers: false,
      )),
    );
  }

  void _onSelection(AdminUsersSelectionChanged e, Emitter<AdminState> emit) {
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
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final users = await repository.getUsers();
        users.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
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
    final res =
        await repository.bulkDelete(ids: current.selectedUserIds.toList());
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final users = await repository.getUsers();
        final stats = await repository.getStats();
        users.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (u) => stats.fold(
            (f) => emit(adminErr(f.errorMessage, current)),
            (s) =>
                emit(current.copyWith(users: u, stats: s, selectedUserIds: {})),
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
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final matches = await repository.getMatches();
        matches.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (m) => emit(current.copyWith(matches: m, selectedMatchIds: {})),
        );
      },
    );
  }

  Future<void> _onCreateTeam(
      AdminCreateTeamRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Creando equipo...', prev: current));
    final res = await repository.createTeam(name: e.name, league: e.league);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final teams = await repository.getTeams();
        teams.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (t) => emit(current.copyWith(teams: t)),
        );
      },
    );
  }

  Future<void> _onCreateLeague(
      AdminCreateLeagueRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Creando liga...', prev: current));
    final res = await repository.createLeague(name: e.name);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final leagues = await repository.getLeagues();
        leagues.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (l) => emit(current.copyWith(leagues: l)),
        );
      },
    );
  }

  Future<void> _onToggleField(
      AdminToggleFieldRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    final res = await repository.toggleFieldStatus(id: e.id, status: e.status);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final fields = await repository.getFields();
        fields.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (fl) => emit(current.copyWith(fields: fl)),
        );
      },
    );
  }

  Future<void> _refreshTeams(Emitter<AdminState> emit, AdminLoaded cur) async {
    final teams = await repository.getTeams();
    teams.fold(
      (f) => emit(AdminError(f.errorMessage, cur)),
      (t) => emit(cur.copyWith(teams: t)),
    );
  }

  Future<void> _onUpdateTeam(
      AdminUpdateTeamRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Actualizando equipo...', prev: current));
    final res = await repository.updateTeam(id: e.id, name: e.name);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async => _refreshTeams(emit, current),
    );
  }

  Future<void> _onDeleteTeam(
      AdminDeleteTeamRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Borrando equipo...', prev: current));
    final res = await repository.deleteTeam(id: e.id);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async => _refreshTeams(emit, current),
    );
  }

  Future<void> _onAddPlayerToTeam(
      AdminAddPlayerToTeamRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    final res = await repository.addPlayerToTeam(
        teamId: e.teamId, playerId: e.playerId);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final teams = await repository.getTeams();
        teams.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (t) => emit(current.copyWith(teams: t)),
        );
      },
    );
  }

  Future<void> _onRemovePlayerFromTeam(
      AdminRemovePlayerFromTeamRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    final res = await repository.removePlayerFromTeam(
        teamId: e.teamId, playerId: e.playerId);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final teams = await repository.getTeams();
        teams.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (t) => emit(current.copyWith(teams: t)),
        );
      },
    );
  }

  Future<void> _onCreateField(
      AdminCreateFieldRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Creando campo...', prev: current));
    final res = await repository.createField(
        name: e.name, price: e.price, capacity: e.capacity);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final fields = await repository.getFields();
        fields.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (fl) => emit(current.copyWith(fields: fl)),
        );
      },
    );
  }

  Future<void> _onDeleteField(
      AdminDeleteFieldRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Borrando campo...', prev: current));
    final res = await repository.deleteField(id: e.id);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final fields = await repository.getFields();
        fields.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (fl) => emit(current.copyWith(fields: fl)),
        );
      },
    );
  }

  Future<void> _onCreateReferee(
      AdminCreateRefereeRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Añadiendo árbitro...', prev: current));
    final res = await repository.createReferee(name: e.name, fee: e.fee);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final refs = await repository.getReferees();
        refs.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (r) => emit(current.copyWith(referees: r)),
        );
      },
    );
  }

  Future<void> _onToggleReferee(
      AdminToggleRefereeRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    final res = await repository.updateReferee(id: e.id, status: e.status);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final refs = await repository.getReferees();
        refs.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (r) => emit(current.copyWith(referees: r)),
        );
      },
    );
  }

  Future<void> _onDeleteReferee(
      AdminDeleteRefereeRequested e, Emitter<AdminState> emit) async {
    final current = state;
    if (current is! AdminLoaded) return;
    emit(AdminActionRunning(message: 'Quitando árbitro...', prev: current));
    final res = await repository.deleteReferee(id: e.id);
    await res.fold(
      (f) async => emit(adminErr(f.errorMessage, current)),
      (_) async {
        final refs = await repository.getReferees();
        refs.fold(
          (f) => emit(adminErr(f.errorMessage, current)),
          (r) => emit(current.copyWith(referees: r)),
        );
      },
    );
  }
}
