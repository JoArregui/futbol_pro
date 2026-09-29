import 'package:equatable/equatable.dart';

class Tournament extends Equatable {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final int maxTeams;
  final int registeredTeams;
  final String status;

  const Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.maxTeams,
    required this.registeredTeams,
    required this.status,
  });

  bool get isOpen => status == 'open' && registeredTeams < maxTeams;

  @override
  List<Object> get props =>
      [id, name, description, startDate, maxTeams, registeredTeams, status];
}
