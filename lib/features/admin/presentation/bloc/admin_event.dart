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
  const AdminUsersSelectionChanged(
      {required this.userId, required this.selected});
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

class AdminCreateTeamRequested extends AdminEvent {
  final String name;
  final String league;
  const AdminCreateTeamRequested(this.name, [this.league = '']);
  @override
  List<Object> get props => [name, league];
}

class AdminCreateLeagueRequested extends AdminEvent {
  final String name;
  const AdminCreateLeagueRequested(this.name);
  @override
  List<Object> get props => [name];
}

class AdminToggleFieldRequested extends AdminEvent {
  final String id;
  final String status;
  const AdminToggleFieldRequested(this.id, this.status);
  @override
  List<Object> get props => [id, status];
}

class AdminUpdateTeamRequested extends AdminEvent {
  final String id;
  final String name;
  const AdminUpdateTeamRequested(this.id, this.name);
  @override
  List<Object> get props => [id, name];
}

class AdminDeleteTeamRequested extends AdminEvent {
  final String id;
  const AdminDeleteTeamRequested(this.id);
  @override
  List<Object> get props => [id];
}

class AdminAddPlayerToTeamRequested extends AdminEvent {
  final String teamId;
  final String playerId;
  const AdminAddPlayerToTeamRequested(this.teamId, this.playerId);
  @override
  List<Object> get props => [teamId, playerId];
}

class AdminRemovePlayerFromTeamRequested extends AdminEvent {
  final String teamId;
  final String playerId;
  const AdminRemovePlayerFromTeamRequested(this.teamId, this.playerId);
  @override
  List<Object> get props => [teamId, playerId];
}

class AdminCreateFieldRequested extends AdminEvent {
  final String name;
  final double price;
  final int capacity;
  const AdminCreateFieldRequested(this.name,
      [this.price = 50, this.capacity = 14]);
  @override
  List<Object> get props => [name, price, capacity];
}

class AdminDeleteFieldRequested extends AdminEvent {
  final String id;
  const AdminDeleteFieldRequested(this.id);
  @override
  List<Object> get props => [id];
}

class AdminCreateRefereeRequested extends AdminEvent {
  final String name;
  final double fee;
  const AdminCreateRefereeRequested(this.name, [this.fee = 20]);
  @override
  List<Object> get props => [name, fee];
}

class AdminToggleRefereeRequested extends AdminEvent {
  final String id;
  final String status;
  const AdminToggleRefereeRequested(this.id, this.status);
  @override
  List<Object> get props => [id, status];
}

class AdminDeleteRefereeRequested extends AdminEvent {
  final String id;
  const AdminDeleteRefereeRequested(this.id);
  @override
  List<Object> get props => [id];
}
