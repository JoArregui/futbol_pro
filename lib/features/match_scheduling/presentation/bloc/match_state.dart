part of 'match_bloc.dart';


abstract class MatchState extends Equatable {
  const MatchState();

  @override
  List<Object> get props => [];
}

class MatchInitial extends MatchState {}
class MatchLoading extends MatchState {}

// Nuevo estado: Detalles de un partido cargados correctamente
class MatchLoaded extends MatchState {
  final Match match;
  const MatchLoaded({required this.match});
  
  @override
  List<Object> get props => [match];
}


class MatchScheduledSuccess extends MatchState {
  final Match match;
  const MatchScheduledSuccess(this.match);

  @override
  List<Object> get props => [match];
}

class MatchError extends MatchState {
  final String message;
  const MatchError(this.message);

  @override
  List<Object> get props => [message];
}

class TeamsGeneratedSuccess extends MatchState {
  final TeamPair teamPair; // Contiene Team A y Team B
  
  const TeamsGeneratedSuccess({required this.teamPair});

  @override
  List<Object> get props => [teamPair];
}