part of 'match_detail_bloc.dart';

abstract class MatchDetailState extends Equatable {
  const MatchDetailState();

  @override
  List<Object?> get props => [];
}

class MatchDetailInitial extends MatchDetailState {}

class MatchDetailLoading extends MatchDetailState {}

/// Cargando una acción (proponer/confirmar/reportar) conservando el detalle.
class MatchDetailActionRunning extends MatchDetailState {
  final Match match;

  const MatchDetailActionRunning({required this.match});

  @override
  List<Object> get props => [match];
}

class MatchDetailLoaded extends MatchDetailState {
  final Match match;

  /// Mensaje de éxito transitorio (propuesta, confirmación, no-show).
  final String? notice;

  /// Error de la última acción sin perder el detalle cargado.
  final String? error;

  /// División de cuenta (se carga bajo demanda).
  final MatchSplit? split;

  /// Acta del partido (se carga bajo demanda).
  final MatchActa? acta;

  const MatchDetailLoaded(
      {required this.match, this.notice, this.error, this.split, this.acta});

  MatchDetailLoaded copyWith(
      {Match? match,
      String? notice,
      String? error,
      MatchSplit? split,
      MatchActa? acta}) {
    return MatchDetailLoaded(
      match: match ?? this.match,
      notice: notice ?? this.notice,
      error: error,
      split: split ?? this.split,
      acta: acta ?? this.acta,
    );
  }

  @override
  List<Object?> get props => [match, notice, error, split, acta];
}

class MatchDetailError extends MatchDetailState {
  final String message;

  const MatchDetailError(this.message);

  @override
  List<Object> get props => [message];
}
