part of 'admin_bloc.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final AdminStats stats;
  final List<AdminUser> users;
  final List<AdminMatch> matches;
  final Set<String> selectedUserIds;
  final Set<String> selectedMatchIds;
  final bool searchingUsers;

  // Gestión completa
  final List<AdminTeam> teams;
  final List<AdminPlayer> players;
  final List<AdminField> fields;
  final List<AdminReferee> referees;
  final List<AdminLeague> leagues;
  final List<AdminMatch> friendlies;
  final List<AdminTournament> tournaments;
  final AdminFinance finance;
  final List<AdminAudit> audit;

  const AdminLoaded({
    required this.stats,
    required this.users,
    required this.matches,
    this.selectedUserIds = const {},
    this.selectedMatchIds = const {},
    this.searchingUsers = false,
    this.teams = const [],
    this.players = const [],
    this.fields = const [],
    this.referees = const [],
    this.leagues = const [],
    this.friendlies = const [],
    this.tournaments = const [],
    this.finance = const AdminFinance(
      totalRevenue: 0,
      monthRevenue: 0,
      pending: 0,
      byMonth: [],
    ),
    this.audit = const [],
  });

  AdminLoaded copyWith({
    AdminStats? stats,
    List<AdminUser>? users,
    List<AdminMatch>? matches,
    Set<String>? selectedUserIds,
    Set<String>? selectedMatchIds,
    bool? searchingUsers,
    List<AdminTeam>? teams,
    List<AdminPlayer>? players,
    List<AdminField>? fields,
    List<AdminReferee>? referees,
    List<AdminLeague>? leagues,
    List<AdminMatch>? friendlies,
    List<AdminTournament>? tournaments,
    AdminFinance? finance,
    List<AdminAudit>? audit,
  }) => AdminLoaded(
    stats: stats ?? this.stats,
    users: users ?? this.users,
    matches: matches ?? this.matches,
    selectedUserIds: selectedUserIds ?? this.selectedUserIds,
    selectedMatchIds: selectedMatchIds ?? this.selectedMatchIds,
    searchingUsers: searchingUsers ?? this.searchingUsers,
    teams: teams ?? this.teams,
    players: players ?? this.players,
    fields: fields ?? this.fields,
    referees: referees ?? this.referees,
    leagues: leagues ?? this.leagues,
    friendlies: friendlies ?? this.friendlies,
    tournaments: tournaments ?? this.tournaments,
    finance: finance ?? this.finance,
    audit: audit ?? this.audit,
  );

  @override
  List<Object> get props => [
    stats,
    users,
    matches,
    selectedUserIds,
    selectedMatchIds,
    searchingUsers,
    teams,
    players,
    fields,
    referees,
    leagues,
    friendlies,
    tournaments,
    finance,
    audit,
  ];
}

class AdminActionRunning extends AdminState {
  final String message;
  final AdminLoaded prev;
  const AdminActionRunning({required this.message, required this.prev});
  @override
  List<Object> get props => [message, prev];
}

class AdminError extends AdminState {
  final String message;

  /// Estado anterior para restaurar lista/selección/scroll en la UI.
  final AdminLoaded? prev;
  const AdminError(this.message, [this.prev]);
  @override
  List<Object> get props => [message, prev ?? ''];
}

/// Helper: error conservando la lista visible cuando hay estado previo.
AdminError adminErr(String message, AdminState current) =>
    AdminError(message, current is AdminLoaded ? current : null);
