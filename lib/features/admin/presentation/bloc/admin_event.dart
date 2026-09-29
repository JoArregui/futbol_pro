part of 'admin_bloc.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object> get props => [];
}

class AdminLoadRequested extends AdminEvent {
  const AdminLoadRequested();
}

class AdminUsersSearchRequested extends AdminEvent {
  final String query;
  const AdminUsersSearchRequested(this.query);
  @override
  List<Object> get props => [query];
}

class AdminUsersSelectionChanged extends AdminEvent {
  final String userId;
  final bool selected;
  const AdminUsersSelectionChanged({required this.userId, required this.selected});
  @override
  List<Object> get props => [userId, selected];
}

class AdminBulkRoleRequested extends AdminEvent {
  final String role;
  const AdminBulkRoleRequested(this.role);
  @override
  List<Object> get props => [role];
}

class AdminBulkDeleteRequested extends AdminEvent {
  const AdminBulkDeleteRequested();
}

class AdminMatchesSelectionChanged extends AdminEvent {
  final String matchId;
  final bool selected;
  const AdminMatchesSelectionChanged(
      {required this.matchId, required this.selected});
  @override
  List<Object> get props => [matchId, selected];
}

class AdminBulkCancelMatchesRequested extends AdminEvent {
  const AdminBulkCancelMatchesRequested();
}
