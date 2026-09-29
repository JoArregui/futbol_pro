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

  const AdminLoaded({
    required this.stats,
    required this.users,
    required this.matches,
    this.selectedUserIds = const {},
    this.selectedMatchIds = const {},
    this.searchingUsers = false,
  });

  AdminLoaded copyWith({
    AdminStats? stats,
    List<AdminUser>? users,
    List<AdminMatch>? matches,
    Set<String>? selectedUserIds,
    Set<String>? selectedMatchIds,
    bool? searchingUsers,
  }) =>
      AdminLoaded(
        stats: stats ?? this.stats,
        users: users ?? this.users,
        matches: matches ?? this.matches,
        selectedUserIds: selectedUserIds ?? this.selectedUserIds,
        selectedMatchIds: selectedMatchIds ?? this.selectedMatchIds,
        searchingUsers: searchingUsers ?? this.searchingUsers,
      );

  @override
  List<Object> get props =>
      [stats, users, matches, selectedUserIds, selectedMatchIds, searchingUsers];
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
  const AdminError(this.message);
  @override
  List<Object> get props => [message];
}
