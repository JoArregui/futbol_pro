import 'package:equatable/equatable.dart';

/// División de la cuenta del partido entre participantes.
class SplitShare extends Equatable {
  final String playerId;
  final String name;
  final double amount;

  const SplitShare(
      {required this.playerId, required this.name, required this.amount});

  factory SplitShare.fromJson(Map<String, dynamic> json) => SplitShare(
        playerId: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object> get props => [playerId, name, amount];
}

class MatchSplit extends Equatable {
  final String matchId;
  final double total;
  final bool hasCost;
  final int participants;
  final double perPerson;
  final List<SplitShare> detail;

  const MatchSplit({
    required this.matchId,
    required this.total,
    required this.hasCost,
    required this.participants,
    required this.perPerson,
    this.detail = const [],
  });

  factory MatchSplit.fromJson(Map<String, dynamic> json) {
    final raw = json['detail'];
    return MatchSplit(
      matchId: (json['matchId'] ?? '').toString(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      hasCost: json['hasCost'] == true,
      participants: (json['participants'] as num?)?.toInt() ?? 0,
      perPerson: (json['perPerson'] as num?)?.toDouble() ?? 0,
      detail: raw is List
          ? raw
              .whereType<Map<dynamic, dynamic>>()
              .map((e) =>
                  SplitShare.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  @override
  List<Object> get props =>
      [matchId, total, hasCost, participants, perPerson, detail];
}
