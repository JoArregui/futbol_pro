part of 'match_detail_bloc.dart';

abstract class MatchDetailState extends Equatable {
  const MatchDetailState();

  @override
  List<Object> get props => [];
}

class MatchDetailInitial extends MatchDetailState {}

class MatchDetailLoading extends MatchDetailState {}

class MatchDetailLoaded extends MatchDetailState {
  final Match match;

  const MatchDetailLoaded({required this.match});

  @override
  List<Object> get props => [match];
}

class MatchDetailError extends MatchDetailState {
  final String message;

  const MatchDetailError(this.message);

  @override
  List<Object> get props => [message];
}