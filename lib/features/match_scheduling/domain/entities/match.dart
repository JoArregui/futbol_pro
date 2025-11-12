import 'package:equatable/equatable.dart';

class Match extends Equatable {
  final String id;
  final String title;
  final DateTime scheduledTime;
  final String fieldId;
  final MatchType type; 
  final List<String> playerIds;

  const Match({
    required this.id,
    required this.title,
    required this.scheduledTime,
    required this.fieldId,
    required this.type,
    required this.playerIds,
  });

  @override
  List<Object> get props => [id, title, scheduledTime, fieldId, type, playerIds];
}

enum MatchType { league, friendly }