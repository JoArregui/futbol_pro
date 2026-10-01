import 'package:equatable/equatable.dart';

class AdminUser extends Equatable {
  final String id;
  final String email;
  final String role;
  final String nickname;
  final String name;

  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.nickname,
    required this.name,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: (json['id'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    role: (json['role'] ?? 'player').toString(),
    nickname: (json['nickname'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
  );

  @override
  List<Object> get props => [id, email, role, nickname, name];
}

class AdminStats extends Equatable {
  final int users;
  final int matches;
  final int fields;
  final int bookings;
  final int chats;
  final int teams;
  final int leagues;
  final int referees;
  final double revenue;

  const AdminStats({
    required this.users,
    required this.matches,
    required this.fields,
    required this.bookings,
    required this.chats,
    this.teams = 0,
    this.leagues = 0,
    this.referees = 0,
    this.revenue = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
    users: (json['users'] as num?)?.toInt() ?? 0,
    matches: (json['matches'] as num?)?.toInt() ?? 0,
    fields: (json['fields'] as num?)?.toInt() ?? 0,
    bookings: (json['bookings'] as num?)?.toInt() ?? 0,
    chats: (json['chats'] as num?)?.toInt() ?? 0,
    teams: (json['teams'] as num?)?.toInt() ?? 0,
    leagues: (json['leagues'] as num?)?.toInt() ?? 0,
    referees: (json['referees'] as num?)?.toInt() ?? 0,
    revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object> get props => [
    users,
    matches,
    fields,
    bookings,
    chats,
    teams,
    leagues,
    referees,
    revenue,
  ];
}

class AdminMatch extends Equatable {
  final String id;
  final String fieldId;
  final String time;
  final String status;
  final String type;

  const AdminMatch({
    required this.id,
    required this.fieldId,
    required this.time,
    required this.status,
    this.type = 'AMISTOSO',
  });

  factory AdminMatch.fromJson(Map<String, dynamic> json) => AdminMatch(
    id: (json['id'] ?? '').toString(),
    fieldId: (json['fieldId'] ?? '').toString(),
    time: (json['time'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    type: (json['type'] ?? 'AMISTOSO').toString(),
  );

  @override
  List<Object> get props => [id, fieldId, time, status, type];
}

// ---------- Nuevas entidades de gestión ----------

class AdminTeam extends Equatable {
  final String id;
  final String name;
  final String league;
  final int players;
  final String captain;
  const AdminTeam({
    required this.id,
    required this.name,
    required this.league,
    required this.players,
    required this.captain,
  });
  factory AdminTeam.fromJson(Map<String, dynamic> j) => AdminTeam(
    id: (j['id'] ?? '').toString(),
    name: (j['nombre'] ?? j['name'] ?? '').toString(),
    league: (j['league'] ?? j['liga'] ?? '').toString(),
    players:
        (j['players'] as num?)?.toInt() ??
        (j['plantilla'] is List ? (j['plantilla'] as List).length : 0),
    captain: (j['captain'] ?? j['capitan'] ?? '').toString(),
  );
  @override
  List<Object> get props => [id, name, league, players, captain];
}

class AdminPlayer extends Equatable {
  final String id;
  final String name;
  final String nickname;
  final String team;
  final int goals;
  final double rating;
  const AdminPlayer({
    required this.id,
    required this.name,
    required this.nickname,
    required this.team,
    required this.goals,
    required this.rating,
  });
  factory AdminPlayer.fromJson(Map<String, dynamic> j) => AdminPlayer(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? j['nombre'] ?? '').toString(),
    nickname: (j['nickname'] ?? j['apodo'] ?? '').toString(),
    team: (j['team'] ?? j['equipo'] ?? '').toString(),
    goals: (j['goals'] as num?)?.toInt() ?? 0,
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
  );
  @override
  List<Object> get props => [id, name, nickname, team, goals, rating];
}

class AdminField extends Equatable {
  final String id;
  final String name;
  final double price;
  final String status;
  final int capacity;
  const AdminField({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    required this.capacity,
  });
  factory AdminField.fromJson(Map<String, dynamic> j) => AdminField(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? j['nombre'] ?? '').toString(),
    price:
        (j['price'] as num?)?.toDouble() ??
        (j['hourlyRate'] as num?)?.toDouble() ??
        (j['tarifa'] as num?)?.toDouble() ??
        0,
    status: (j['status'] ?? j['estado'] ?? 'disponible').toString(),
    capacity:
        (j['capacity'] as num?)?.toInt() ??
        (j['capacidad'] as num?)?.toInt() ??
        0,
  );
  @override
  List<Object> get props => [id, name, price, status, capacity];
}

class AdminReferee extends Equatable {
  final String id;
  final String name;
  final double rating;
  final double fee;
  final String status;
  const AdminReferee({
    required this.id,
    required this.name,
    required this.rating,
    required this.fee,
    required this.status,
  });
  factory AdminReferee.fromJson(Map<String, dynamic> j) => AdminReferee(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? j['nombre'] ?? '').toString(),
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
    fee:
        (j['fee'] as num?)?.toDouble() ??
        (j['tarifa'] as num?)?.toDouble() ??
        0,
    status: (j['status'] ?? j['estado'] ?? 'activo').toString(),
  );
  @override
  List<Object> get props => [id, name, rating, fee, status];
}

class AdminLeague extends Equatable {
  final String id;
  final String name;
  final int teams;
  final String status;
  const AdminLeague({
    required this.id,
    required this.name,
    required this.teams,
    required this.status,
  });
  factory AdminLeague.fromJson(Map<String, dynamic> j) => AdminLeague(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? j['nombre'] ?? '').toString(),
    teams:
        (j['teams'] as num?)?.toInt() ??
        (j['registeredTeams'] as num?)?.toInt() ??
        0,
    status: (j['status'] ?? j['estado'] ?? '').toString(),
  );
  @override
  List<Object> get props => [id, name, teams, status];
}

class AdminTournament extends Equatable {
  final String id;
  final String name;
  final String phase;
  final int teams;
  const AdminTournament({
    required this.id,
    required this.name,
    required this.phase,
    required this.teams,
  });
  factory AdminTournament.fromJson(Map<String, dynamic> j) => AdminTournament(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? j['nombre'] ?? '').toString(),
    phase: (j['phase'] ?? j['fase'] ?? j['status'] ?? '').toString(),
    teams: (j['teams'] as num?)?.toInt() ?? 0,
  );
  @override
  List<Object> get props => [id, name, phase, teams];
}

class AdminAudit extends Equatable {
  final String id;
  final String actorEmail;
  final String action;
  final String entity;
  final String entityId;
  final String createdAt;
  const AdminAudit({
    required this.id,
    required this.actorEmail,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.createdAt,
  });
  factory AdminAudit.fromJson(Map<String, dynamic> j) => AdminAudit(
    id: (j['id'] ?? '').toString(),
    actorEmail: (j['actorEmail'] ?? '').toString(),
    action: (j['action'] ?? '').toString(),
    entity: (j['entity'] ?? '').toString(),
    entityId: (j['entityId'] ?? '').toString(),
    createdAt: (j['createdAt'] ?? '').toString(),
  );
  @override
  List<Object> get props => [
    id,
    actorEmail,
    action,
    entity,
    entityId,
    createdAt,
  ];
}

class FinancePoint extends Equatable {
  final String label;
  final double value;
  const FinancePoint(this.label, this.value);
  @override
  List<Object> get props => [label, value];
}

class AdminFinance extends Equatable {
  final double totalRevenue;
  final double monthRevenue;
  final double pending;
  final List<FinancePoint> byMonth;
  const AdminFinance({
    required this.totalRevenue,
    required this.monthRevenue,
    required this.pending,
    required this.byMonth,
  });
  factory AdminFinance.fromJson(Map<String, dynamic> j) {
    final months = (j['byMonth'] as List?) ?? [];
    return AdminFinance(
      totalRevenue:
          (j['total'] as num?)?.toDouble() ??
          (j['totalRevenue'] as num?)?.toDouble() ??
          0,
      monthRevenue:
          (j['month'] as num?)?.toDouble() ??
          (j['monthRevenue'] as num?)?.toDouble() ??
          0,
      pending: (j['pending'] as num?)?.toDouble() ?? 0,
      byMonth: months
          .map(
            (e) => FinancePoint(
              (e['label'] ?? e['month'] ?? '').toString(),
              ((e['value'] ?? e['total'] ?? 0) as num).toDouble(),
            ),
          )
          .toList(),
    );
  }

  /// Finanzas vacías reales (sin datos inventados).
  /// Úsese cuando el backend no tiene módulo /finance (404).
  factory AdminFinance.empty() => const AdminFinance(
    totalRevenue: 0,
    monthRevenue: 0,
    pending: 0,
    byMonth: [],
  );

  @override
  List<Object> get props => [totalRevenue, monthRevenue, pending, byMonth];
}
